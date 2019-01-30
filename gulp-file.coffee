gulp			= require 'gulp'
gutil			= require 'gulp-util'
# minify		= require 'gulp-minify'
include			= require "gulp-include"
uglify			= require('gulp-uglify-es').default
coffeescript	= require 'gulp-coffeescript'

GfwCompiler		= require '../compiler'

# compile final values (consts to be remplaced at compile time)
# handlers
compileCoffee = ->
	gulp.src 'assets/**/[!_]*.coffee', nodir: true
		# include related files
		.pipe include hardFail: true
		# convert to js
		.pipe coffeescript bare: true
		# template
		.pipe GfwCompiler.template()
		# uglify when prod mode
		.pipe uglify()
		# save 
		.pipe gulp.dest 'build'
		.on 'error', GfwCompiler.logError
# watch files
watch = ->
	gulp.watch ['assets/**/*.coffee'], compileCoffee
	return