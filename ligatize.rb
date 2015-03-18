require 'rubygems'
require 'bundler/setup'
Bundler.require
require 'fontcustom/cli'
require 'fileutils'

ROOT_FOLDER = File.join(File.dirname(__FILE__), '..')
FONT_EM_SIZE = 2048
STOCK_FONT_PATH = File.join(ROOT_FOLDER, 'DroidSans.ttf')

def make_custom_svg_font
  Fontcustom::Base.new(
    input: File.join(ROOT_FOLDER, 'glyphs'),
    font_em: FONT_EM_SIZE,
    no_hash: true,
    output: File.join(ROOT_FOLDER, 'tmp', 'custom')
  ).compile
end

def decompile_stock_font
  decomp_path = File.join(ROOT_FOLDER, 'tmp', 'stock_decompiled')
  FileUtils.mkpath decomp_path
  system("ttx -s -d \"#{decomp_path}\" \"#{STOCK_FONT_PATH}\"")
end

def decompile_custom_font
  custom_font_path = File.join(ROOT_FOLDER, 'tmp', 'custom', 'fontcustom.ttf')
  decomp_path = File.join(ROOT_FOLDER, 'tmp', 'custom_decompiled')
  FileUtils.mkpath decomp_path
  system("ttx -s -d \"#{decomp_path}\" \"#{custom_font_path}\"")
end

make_custom_svg_font
decompile_custom_font
