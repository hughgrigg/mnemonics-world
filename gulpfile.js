/*jslint node: true */
"use strict";

var gulp        = require("gulp");
var runSequence = require("run-sequence");
var clean       = require("gulp-clean");
var copy        = require("gulp-copy");
var rev         = require("gulp-rev");
var sass        = require("gulp-sass");
var scssLint    = require("gulp-scss-lint");
var sourceMap   = require("gulp-sourcemaps");
var autoPrefix  = require("gulp-autoprefixer");
var cleanCSS    = require("gulp-clean-css");
var webpack     = require('webpack-stream');
var template    = require('gulp-template');

gulp.task("default", function (callback) {
    return runSequence(
        "clean",
        ["copy", "styles", "scripts"],
        "asset-template",
        callback
    );
});

gulp.task("clean", function () {
    return gulp.src([
        "./cache/**/*.php",
        "./public/css/**/*.*",
        "./public/js/**/*.*",
        "./public/img/**/*.*",
        "./views/build/**/*.*"
    ]).pipe(clean());
});

gulp.task("copy", function () {
    return gulp.src("./resources/assets/img/**")
        .pipe(copy("./public/img/", {prefix: 3}));
});

gulp.task("styles", function () {
    return gulp.src([
        "./resources/assets/sass/front.scss"
    ])
        .pipe(sass({
            includePaths: [
                "./node_modules/foundation-sites/scss/",
                "./node_modules/motion-ui/src/"
            ]
        }))
        .pipe(sourceMap.init())
        .pipe(autoPrefix({
            browsers: ["last 2 versions", "ie >= 9", "and_chr >= 2.3"]
        }))
        .pipe(cleanCSS())
        .pipe(rev())
        .pipe(sourceMap.write("."))
        .pipe(gulp.dest("./public/css"))
        .pipe(rev.manifest("rev_manifest.json"))
        .pipe(gulp.dest("./public/css/"));
});

gulp.task("scss-lint", function () {
    return gulp.src([
        "./resources/assets/sass/**/*.scss",
        "!**/vendor/**",
        "!**/bootstrap-variables.scss"
    ])
        .pipe(scssLint())
        .pipe(scssLint.failReporter());
});

gulp.task("scripts", function () {
    return gulp.src("./resources/assets/js/front.js")
        .pipe(webpack(require("./webpack.config.js")))
        .pipe(gulp.dest("public/js/"));
});

gulp.task("asset-template", ["styles", "scripts"], function () {
    return gulp.src("./resources/assets/assets.volt")
        .pipe(template({
            css: require("./public/css/rev_manifest.json")["front.css"],
            js:  require("./public/js/webpack-assets.json").main.js
        }))
        .pipe(gulp.dest("./app/views/build/"));
});
