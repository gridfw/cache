gulp			= require 'gulp'
gutil			= require 'gulp-util'
# minify		= require 'gulp-minify'
include			= require "gulp-include"
uglify			= require('gulp-uglify-es').default
coffeescript	= require 'gulp-coffeescript'

GfwCompiler		= require '../compiler'

# settings
settings=
	mode: gutil.env.mode || 'dev'
	isProd: gutil.env.mode is 'prod'
# compile final values (consts to be remplaced at compile time)
# handlers
compileCoffee = ->
	glp= gulp.src 'assets/**/[!_]*.coffee', nodir: true
		# include related files
		.pipe include hardFail: true
		# template
		.pipe GfwCompiler.template(settings).on 'error', GfwCompiler.logError
		# convert to js
		.pipe coffeescript bare: true
		# uglify when prod mode
	# if is prod
	if settings.isProd
		glp = glp.pipe uglify()
	# save 
	glp.pipe gulp.dest 'build'
	.on 'error', GfwCompiler.logError
# watch files
watch = (cb)->
	unless settings.isProd
		gulp.watch ['assets/**/*.coffee'], compileCoffee
	cb()
	return

# default task
gulp.task 'default', gulp.series compileCoffee, watch