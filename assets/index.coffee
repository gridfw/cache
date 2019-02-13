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

fs = require 'fs'

### CACHE ###
module.exports = class Cache
	###*
	 * Cache
	 * @param {Number} settings.size - aproximative cache max size in bytes
	 * @param  {number} settings.timeout - timeout in ms
	 * @param {function} onRemove - callback when removing an antity
	 * @param {function} create - create an antity
	###
	constructor: (settings)->
		throw new Error 'Settings required' unless settings
		throw new Error 'settings.create expected functions' unless typeof settings.create is 'function'
		throw new Error 'settings.onRemove expected functions' unless typeof settings.onRemove is 'function'
		# cache object
		# key: [lastStep, approximativeFileSize]
		@<%=cache %> = _create null
		@<%=bytes %>= 0
		@<%=length %>= 0
		@<%=create %> = _wrapCreate settings.create
		@<%=onRemove %> = settings.onRemove
		# log
		@info = settings.info if typeof settings.info is 'function'
		@error = settings.error if typeof settings.error is 'function'
		return
	# reload function
	reload: (settings)->
		settings ?= _create null
		@<%=maxSize %> = settings.maxSize || 0
		@<%=maxStep %> = settings.maxStep || 500 # remove item after 500 steps
		# get method
		if @<%=maxSize %> is 0 # disabled
			getMethod= _getCacheDisabled
			@clear() # clear all data
		# infinity, keep always data in memory
		else if @<%=maxSize %> is Infinity
			getMethod= _getCacheInfinity
			@clear() # clear all data
		# enabled
		else
			getMethod= _getCacheEnabled
		Object.defineProperty this, 'get',
			configurable: on
			value: getMethod
		return
	# error
	error: (err)-> console.log 'Cache Error>> ', err
	info: (info)-> console.info 'Cache Info>> ', info
	# clear all data
	clear: ->
		# clear all data
		cacheQ = @<%=cache %>
		for k,v of cacheQ
			try
				delete cacheQ[k]
				@<%=onRemove %> k
			catch err
				@error err
		# flags
		@<%=bytes %>= 0
		@<%=length %>= 0
		# return self
		return this

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
		throw 404 if value is null
	else
		try
			value = @<%=create %> key
			unit= @<%=cache %>[key] = [0, 0, value]
			++@<%=length %>
			# enable interval
			unless @<%=interval %>
				_cleanInterv this
			# look for file size
			fs.stat key, (err, stats)->
				if stats
					@<%=bytes %> += (unit[1] = stats.size)
		catch err
			if err is 404
				@<%=cache %>[key] = [0, 0, null]
			throw err
	# return value
	return value

###
# do not empty cache: will increase performance, but use more memory
###
_getCacheInfinity= (key)->
	value= @<%=cache %>[key]
	unless value
		# entry not found
		throw 404 if value is null
		# new entry
		try
			value= @<%=cache %>[key]= @<%=create %> key
		catch err
			# keep this info
			@<%=cache %>[key]= null if err is 404
			# throw error
			throw 404
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
			cache.info "Change interval to: #{currentInterval}"
			clearInterval cache.<%=interval %>
			cache.<%=interval %> = setInterval (-> _cleanInterv cache), currentInterval
	return

###*
 * Wrap create
###
_wrapCreate = (fx)->
	(key)->
		try
			return fx key
		catch err
			throw 404 if err? and (err.code is 'MODULE_NOT_FOUND') and (err.message.indexOf(key) isnt -1) # module not found
			throw err
		