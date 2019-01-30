# attributes abreviations
<%
const create = 'c',
	onRemove= 'r',
	cache = 'q',
	maxStep= 't', //# max step, when cache ecceds that number, it will be removed
	maxSize= 'm',
	bytes = 'b', //# Total size in bytes
	length= 'l', //# nbr of items inside cache
	currentInterval= 'i', //# current interval in ms
	interval= 'v' //# interval link (to be used by: clearInterval)
%>

# UTILS
_defineProperty = Object.defineProperty
_create = Object.create

### CACHE ###
module.exports = class Cache
	###*
	 * Cache
	 * @param {Number} settings.size - aproximative cache max size in bytes
	 * @param  {number} settings.timeout - timeout in ms
	 * @param {function} onRemove - callback when removing an antity
	 * @param {function} create - create an antity
	###
	constructor: ->
		# cache object
		# key: [lastStep, approximativeFileSize]
		@<%=cache %> = _create null
		@<%=bytes %>= 0
		@<%=length %>= 0
		return
	# reload function
	reload: (settings)->
		settings ?= _create null
		@<%=create %> = settings.create
		@<%=onRemove %> = settings.onRemove
		@<%=maxSize %> = settings.maxSize || 0
		@<%=maxStep %> = settings.maxStep || 500 # remove item after 500 steps

		# get method
		if @<%=maxSize %> is 0 # disabled
			Object.defineProperty this, 'get',
				configurable: on
				value: _getCacheDisabled
		# enabled
		else
			Object.defineProperty this, 'get',
				configurable: on
				value: _getCacheEnabled
		return
	# error
	error: (err)-> console.log 'Cache Error>> ', err
	# clear all data
	clear: ->
		@<%=bytes %>= 0
		@<%=length %>= 0

### getters ###
Object.defineProperties Cache.prototype,
	length: get: -> @<%=length %>
	bytes: get: -> @<%=bytes %>
###*
 * Get fx when cache is disabled
###
_getCacheDisabled = (key)->
	# get value
	value = @<%=create %> key
	# remvoe from cache
	@<%=onRemove %> key
	# return value
	return value
###*
 * Get fx when cache is enabled
 * @type {[type]}
###
_getCacheEnabled = (key)->
	# caching process
	unit = @<%=cache %>[key]
	if unit
		unit[0] = 0 # refresh step
		value = unit[2]
	else
		value = @<%=create %> key
		unit= @<%=cache %>[key] = [0, 0, value]
		++@<%=length %>
		# enable interval
		unless cache.<%=interval %>
			_cleanInterv this
		# look for file size
		fs.stat key, (err, stats)->
			if stats
				@<%=bytes %> += (unit[1] = stats.size)
	# return value
	return value


### interval menage ###
INTERVALS = [10000, 5000, 2000, 1000, 500]
INTR_FACT = [2    , 1.4 , 1.2 , 1]
_cleanInterv = (cache)->
	count = 0
	maxSteps = cache.<%=maxStep %>
	maxSize = cache.<%=maxSize %>
	# remove items with max step
	currentSize = 0
	cacheQ = cache.<%=cache %>
	for k,v of cacheQ
		try
			# v = [currentStep, fileSize, item]
			if v[0] > maxSteps
				delete cacheQ[k]
				cache.<%=onRemove %> k
			# still in queu
			else
				++v[0]
				currentSize += v[1]
				++count
		catch err
			cache.error err
	# save info
	cache.<%=length %> = count
	cache.<%=bytes %> = currentSize
	# disable interval if cache is empty
	if count is 0
		clearInterval cache.<%=interval %>
		cache.<%=interval %> = null
	# reload interval
	else if currentSize
		currentInterval= cache.<%=currentInterval %>
		maxSize = cache.<%=maxSize %>
		factor = maxSize / currentSize

		# get current interval to use
		cIntervIdx = 0;
		for v in INTR_FACT
			break if factor > v
			++cIntervIdx
		# change interval if not the same
		unless currentInterval is INTERVALS[cIntervIdx]
			currentInterval= cache.<%=currentInterval %> = INTERVALS[cIntervIdx]
			clearInterval cache.<%=interval %>
			cache.<%=interval %> = setInterval (-> _cleanInterv cache), currentInterval
	return