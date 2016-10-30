var webpack      = require("webpack");
var AssetsPlugin = require("assets-webpack-plugin");

module.exports = {
    devtool: "source-map",
    module:  {
        loaders: [{
            test:   /\.js$/,
            loader: "babel-loader"
        }]
    },
    plugins: [
        new webpack.optimize.UglifyJsPlugin(),
        new AssetsPlugin({path: "public/js/"})
    ]
};
