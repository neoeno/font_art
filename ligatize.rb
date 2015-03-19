require 'rubygems'
require 'bundler/setup'
Bundler.require

require_relative 'lib/font_art/ligature_builder'

ROOT_FOLDER = File.expand_path File.join(File.dirname(__FILE__))

FontArt::LigatureBuilder.build(
  stock_name: "DroidSans",
  stock_file: File.join(ROOT_FOLDER, 'fonts', 'DroidSans.ttf'),
  custom_name: "icomoon",
  custom_file: File.join(ROOT_FOLDER, 'fonts', 'icomoon.ttf'),
  synth_file: File.join(ROOT_FOLDER, 'builds', 'synth.ttf'))
