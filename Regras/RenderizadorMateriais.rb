# ==============================================================================
# PINTOR DA FÁBRICA: TEXTURAS E FITAS DE BORDA (Regras/RenderizadorMateriais.rb)
# ==============================================================================
require_relative 'CatalogoMateriais'

class RenderizadorMateriais

  def self.obter_ou_criar_material_skp(id_material)
    return obter_material_cru if id_material.nil? || id_material == 0 || id_material.to_s.empty?

    model = Sketchup.active_model
    mats = model.materials
    dados_mat = CatalogoMateriais.obter(id_material.to_s)
    
    return obter_material_cru unless dados_mat

    # Nome único para a coleção de materiais do SketchUp
    nome_skp = "TiranoGio_#{dados_mat['fabricante']}_#{dados_mat['nome']}".gsub(/[^0-9A-Za-z_-]/, '_')
    mat_skp = mats[nome_skp]

    unless mat_skp
      mat_skp = mats.add(nome_skp)
      
      # 1. Atribui a cor RGB base sólida
      rgb = dados_mat['cor_rgb'] || [245, 245, 245]
      mat_skp.color = Sketchup::Color.new(rgb[0], rgb[1], rgb[2])

      # 2. Carrega e dimensiona a textura JPG/PNG se especificada no JSON
      if dados_mat['textura_url'] && !dados_mat['textura_url'].to_s.empty?
        raiz_plugin = File.expand_path('..', __dir__)
        
        # Normalização de caminho de arquivos para compatibilidade Windows (barras '\' vs '/')
        caminho_relativo = dados_mat['textura_url'].tr('/', File::ALT_SEPARATOR || File::SEPARATOR)
        caminho_textura = File.join(raiz_plugin, caminho_relativo)

        if File.exist?(caminho_textura)
          mat_skp.texture = caminho_textura
          
          # Dimensões da chapa em mm convertidas para polegadas (unidade interna do SketchUp)
          dim_chapa = dados_mat['dimensoes_chapa'] || {}
          comp_mm = (dim_chapa['comprimento'] || 2750.0).to_f
          larg_mm = (dim_chapa['largura'] || 1850.0).to_f

          comp_pol = comp_mm / 25.4
          larg_pol = larg_mm / 25.4

          # Aplica a escala real do padrão na face do MDF
          mat_skp.texture.size = [comp_pol, larg_pol]
          puts "🎨 Textura carregada com sucesso: #{dados_mat['nome']} (#{caminho_textura})"
        else
          puts "⚠️ Aviso: Textura '#{dados_mat['textura_url']}' não encontrada em #{caminho_textura}. Mantendo cor RGB sólida."
        end
      end
    end

    mat_skp
  end

  def self.obter_material_cru
    model = Sketchup.active_model
    mats = model.materials
    cru = mats["TiranoGio_MDF_Cru"]
    unless cru
      cru = mats.add("TiranoGio_MDF_Cru")
      cru.color = Sketchup::Color.new(205, 175, 130)
    end
    cru
  end

  def self.aplicar(grupo_skp, peca)
    faces = grupo_skp.entities.grep(Sketchup::Face)
    return if faces.length < 6

    id_mat_peca = peca.respond_to?(:material) && peca.material ? peca.material : "generico_branco_tx"
    mat_revestimento = obter_ou_criar_material_skp(id_mat_peca)
    mat_cru = obter_material_cru()

    faces_ordenadas = faces.sort_by { |f| f.area }
    face_prancha_1 = faces_ordenadas[-1]
    face_prancha_2 = faces_ordenadas[-2]

    fitas = peca.respond_to?(:fita_borda) && peca.fita_borda.is_a?(Hash) ? peca.fita_borda : {}

    faces.each do |face|
      # Pranchas principais do MDF recebem a textura/revestimento da chapa
      if face == face_prancha_1 || face == face_prancha_2
        face.material = mat_revestimento
        face.back_material = mat_revestimento
        next
      end

      nx, ny, nz = face.normal.x.round(1), face.normal.y.round(1), face.normal.z.round(1)

      id_fita = nil
      id_fita = fitas[:frontal] || fitas["frontal"] if ny == -1.0
      id_fita = fitas[:traseira] || fitas["traseira"] if ny == 1.0
      id_fita = fitas[:esquerda] || fitas["esquerda"] if nx == -1.0
      id_fita = fitas[:direita] || fitas["direita"] if nx == 1.0
      id_fita = fitas[:superior] || fitas["superior"] if nz == 1.0
      id_fita = fitas[:inferior] || fitas["inferior"] if nz == -1.0

      if id_fita == 1 || id_fita == true
        mat_topo = mat_revestimento
      elsif id_fita.is_a?(String) && !id_fita.empty?
        mat_topo = obter_ou_criar_material_skp(id_fita)
      else
        mat_topo = obter_ou_criar_material_skp("generico_mdf_cru")
      end

      face.material = mat_topo
      face.back_material = mat_topo
    end
  end
end