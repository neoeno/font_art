require 'fileutils'

module FontArt
  class LigatureBuilder

    def self.build(*args)
      new(*args).build!
    end

    def initialize(stock_name:, stock_file:, custom_name:, custom_file:, synth_file:)
      @stock_name = stock_name
      @stock_file = stock_file
      @custom_name = custom_name
      @custom_file = custom_file
      @synth_file = synth_file
      @glyphs_added = []
    end

    def build!
      Dir.mktmpdir do |dir|
        begin
          Dir.chdir(dir)

          decompile_stock_font
          decompile_ligature_font
          prepare_synth_font
          copy_glyph_order
          copy_glyph_dimensions
          copy_glyph_map
          copy_glyphs
          copy_gsub_table
          build_synth_font
        rescue
          binding.pry
        end
      end
    end

    def decompile_stock_font
      FileUtils.mkpath stock_path
      system("ttx -s -d \"#{stock_path}\" \"#{@stock_file}\"")
    end

    def decompile_ligature_font
      FileUtils.mkpath custom_path
      system("ttx -s -d \"#{custom_path}\" \"#{@custom_file}\"")
    end

    def prepare_synth_font
      FileUtils.cp_r(stock_path, 'synth_decompiled')
    end

    def copy_glyph_order
      custom_order, synth_order = get_ligature_and_synth_table('GlyphOrder')

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
      custom_dims, synth_dims = get_ligature_and_synth_table('_h_m_t_x')

      @glyphs_added.each do |name|
        synth_dims.css('hmtx').first.children << custom_dims.css('[name="' + name + '"]').first
      end

      write_synth_table('_h_m_t_x', synth_dims)
    end

    def copy_glyph_map
      custom_map, synth_map = get_ligature_and_synth_table('_c_m_a_p')

      synth_map.css('cmap_format_4').each do |map_table|
        @glyphs_added.each do |name|
          # There are actually two of these in custom_map, but they're identical
          map_table.children << custom_map.css('[name="' + name + '"]').first
        end
      end

      write_synth_table('_c_m_a_p', synth_map)
    end

    def copy_glyphs
      custom_glyphs, synth_glyphs = get_ligature_and_synth_table('_g_l_y_f')

      @glyphs_added.each do |name|
        synth_glyphs.css('glyf').first.children << custom_glyphs.css('[name="' + name + '"]').first
      end

      write_synth_table('_g_l_y_f', synth_glyphs)
    end

    def copy_gsub_table
      custom_gsub, synth_gsub = get_ligature_and_synth_table('G_S_U_B_')

      synth_gsub.css('LookupList').first.children = custom_gsub.css('LookupList').first.children

      write_synth_table('G_S_U_B_', synth_gsub)
    end

    def build_synth_font
      FileUtils.rm(@synth_file) if File.exist? @synth_file
      system("ttx -o \"#{@synth_file}\" \"#{synth_path}/#{@stock_name}.ttx\"")
    end

    private

    def get_ligature_and_synth_table(table_type)
      [
        Oga.parse_xml(
          File.open(File.join(custom_path, @custom_name + '.' + table_type + '.ttx'))),
        Oga.parse_xml(
          File.open(File.join(synth_path, @stock_name + '.' + table_type + '.ttx')))
      ]
    end

    def xml_elem(xml)
      Oga.parse_xml(xml).children.first
    end

    def write_synth_table(table_type, document)
      File.write(File.join(synth_path, @stock_name + '.' + table_type + '.ttx'), document.to_xml)
    end

    def stock_path
      FileUtils.mkpath('stock_decompiled').first
    end

    def custom_path
      FileUtils.mkpath('custom_decompiled').first
    end

    def synth_path
      FileUtils.mkpath('synth_decompiled').first
    end

  end
end
