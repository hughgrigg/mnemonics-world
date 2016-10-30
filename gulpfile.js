/*jslint node: true */
"use strict";

var gulp       = require("gulp");
var rev        = require("gulp-rev");
var sass       = require("gulp-sass");
var scssLint   = require("gulp-scss-lint");
var sourceMap  = require("gulp-sourcemaps");
var autoPrefix = require("gulp-autoprefixer");
var cleanCSS   = require("gulp-clean-css");
var webpack    = require('webpack-stream');
var template   = require('gulp-template');

gulp.task("default", ["styles", "scripts", "asset-template"]);

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

gulp.task("sass:watch", function () {
    gulp.watch("./resources/assets/sass/**/*.scss", ["styles"]);
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
