var webpack = require("webpack");
var path = require("path");

var BUILD_DIR = path.resolve(__dirname, "chrome/scripts/");
var APP_DIR = path.resolve(__dirname, "src/");

var config = {
	entry: {
		popup: APP_DIR + "/main.jsx",
		background: APP_DIR + "/background.js"
	},
	output: {
		path: BUILD_DIR,
		filename: "[name].bundle.js"
	},
	module: {
		loaders: [
			{
				test: /\.jsx?/,
				include: APP_DIR,
				loader: "babel"
			}
		]
	}
};

module.exports = config
