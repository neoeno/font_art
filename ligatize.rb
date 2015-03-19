require 'rubygems'
require 'bundler/setup'
Bundler.require
require 'fontcustom/cli'
require 'fileutils'

ROOT_FOLDER = File.join(File.dirname(__FILE__), '..')
FONT_EM_SIZE = 2048
STOCK_FONT_PATH = File.join(ROOT_FOLDER, 'DroidSans.ttf')

@glyphs_added = []

def decompile_stock_font
  decomp_path = File.join(ROOT_FOLDER, 'tmp', 'stock_decompiled')
  FileUtils.mkpath decomp_path
  system("ttx -s -d \"#{decomp_path}\" \"#{STOCK_FONT_PATH}\"")
end

def decompile_custom_font
  custom_font_path = File.join(ROOT_FOLDER, 'icomoon.ttf')
  decomp_path = File.join(ROOT_FOLDER, 'tmp', 'custom_decompiled')
  FileUtils.mkpath decomp_path
  system("ttx -s -d \"#{decomp_path}\" \"#{custom_font_path}\"")
end

def prepare_synth_font
  stock_path = File.join(ROOT_FOLDER, 'tmp', 'stock_decompiled')
  synth_path = File.join(ROOT_FOLDER, 'tmp', 'synth_decompiled')
  FileUtils.cp_r(stock_path, synth_path)
end

def get_custom_and_synth_table(table_type)
  custom_path = File.join(ROOT_FOLDER, 'tmp', 'custom_decompiled')
  synth_path = File.join(ROOT_FOLDER, 'tmp', 'synth_decompiled')

  [
    Oga.parse_xml(
      File.open(File.join(custom_path, 'icomoon.' + table_type + '.ttx'))),
    Oga.parse_xml(
      File.open(File.join(synth_path, 'DroidSans.' + table_type + '.ttx')))
  ]
end

def write_synth_table(table_type, document)
  synth_path = File.join(ROOT_FOLDER, 'tmp', 'synth_decompiled')

  File.write(File.join(synth_path, 'DroidSans.' + table_type + '.ttx'), document.to_xml)
end

def copy_glyph_order
  custom_order, synth_order = get_custom_and_synth_table('GlyphOrder')

  custom_glyphs = custom_order.css('GlyphID')

  while custom_glyphs.last.attribute('name').value.include? 'uniF'
    glyph = custom_glyphs.pop
    last_id = synth_order.css('GlyphID').last.attribute('id').value.to_i
    glyph.set('id', (last_id + 1).to_s)
    synth_order.css('GlyphOrder').first.children << glyph
    @glyphs_added.push(glyph.attribute('name').value)
  end

  write_synth_table('GlyphOrder', synth_order)
end

def copy_glyph_dimensions
  custom_dims, synth_dims = get_custom_and_synth_table('_h_m_t_x')

  @glyphs_added.each do |name|
    synth_dims.css('hmtx').first.children << custom_dims.css('[name="' + name + '"]').first
  end

  write_synth_table('_h_m_t_x', synth_dims)
end

def copy_glyph_map
  custom_map, synth_map = get_custom_and_synth_table('_c_m_a_p')

  synth_map.css('cmap_format_4').each do |map_table|
    @glyphs_added.each do |name|
      # There are actually two of these in custom_map, but they're identical
      map_table.children << custom_map.css('[name="' + name + '"]').first
    end
  end

  write_synth_table('_c_m_a_p', synth_map)
end

def copy_glyphs
  custom_glyphs, synth_glyphs = get_custom_and_synth_table('_g_l_y_f')

  @glyphs_added.each do |name|
    synth_glyphs.css('glyf').first.children << custom_glyphs.css('[name="' + name + '"]').first
  end

  write_synth_table('_g_l_y_f', synth_glyphs)
end

def xml_elem(xml)
  Oga.parse_xml(xml).children.first
end

def copy_gsub_table
  custom_gsub, synth_gsub = get_custom_and_synth_table('G_S_U_B_')

  synth_gsub.css('LookupList').first.children = custom_gsub.css('LookupList').first.children

  write_synth_table('G_S_U_B_', synth_gsub)
end

def remove_hdmx
  # idk why, FIXME?
  synth_path = File.join(ROOT_FOLDER, 'tmp', 'synth_decompiled')

  FileUtils.rm(File.join(synth_path, 'DroidSans._h_d_m_x.ttx'))

  root_table = Oga.parse_xml(
    File.open(File.join(synth_path, 'DroidSans.ttx')))

  root_table.css('hdmx').first.remove

  File.write(File.join(synth_path, 'DroidSans.ttx'), root_table.to_xml)
end

def build_synth_font
  synth_path = File.join(ROOT_FOLDER, 'tmp', 'synth_decompiled', 'DroidSans.ttx')
  font_path = File.join(ROOT_FOLDER, 'builds', 'synth.ttf')
  FileUtils.rm(font_path) if File.exist? font_path
  system("ttx -o \"#{font_path}\" \"#{synth_path}\"")
end

FileUtils.rm('.fontcustom-manifest.json') if File.exist? '.fontcustom-manifest.json'
FileUtils.remove_dir(File.join(ROOT_FOLDER, 'tmp'))
decompile_stock_font
decompile_custom_font
prepare_synth_font
copy_glyph_order
copy_glyph_dimensions
copy_glyph_map
copy_glyphs
copy_gsub_table
# remove_hdmx
build_synth_font
