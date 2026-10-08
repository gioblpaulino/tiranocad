# ==============================================================================
# MOTOR DE REGRAS: CONSTRUTOR DE ALTOS E ROUPEIROS V3 (Regras/ConstrutorAlto.rb)
# Revisado com Validações Antecipadas Industriais contra Sobrecarga
# ==============================================================================
require_relative 'ConstrutorAereo'
require_relative 'ConstrutorUsinagens'

class ConstrutorAlto

  def self.fabricar(nome, w, h, d, opcoes={})
    perfil = opcoes[:perfil_objeto_custom] || GerenciadorPerfis.obter_perfil(opcoes[:nome_perfil_ativo] || "Padrao_Gemini")
    nom = perfil[:nomenclatura] || {}
    restricoes = perfil[:restricoes_chapa] || {}
    
    # 🚀 REVISÃO DE SEGURANÇA ANTECIPADA (Não cria módulos irreais no SketchUp)
    max_h = restricoes[:comprimento_max_mdf] || 2750.0
    if h > max_h
      puts "⚠️ ConstrutorAlto: Altura #{h}mm excede o limite do MDF físico (#{max_h}mm). Abortando."
      return nil
    end

    esp = perfil[:espessura_mdf] || 15.0
    esp_fnd = perfil[:espessura_fundo] || 6.0
    larg_sarrafo = perfil[:geometria][:largura_sarrafo] || 70.0
    tipo_fixacao = opcoes.fetch(:fixacao, "Duplo_Reforco")
 
    opcoes_reaproveitadas = {
      montagem: opcoes[:montagem],
      fundo_recuado: opcoes.fetch(:fundo_recuado, 15.0),
      fixacao: tipo_fixacao,
      nome_perfil_ativo: opcoes[:nome_perfil_ativo]
    }

    # Instanciação geométrica via motor enclausurado
    modulo = ::ConstrutorAereo.fabricar(nome, w, h, d, opcoes_reaproveitadas)
    return nil if modulo.nil?
    
    modulo.familia = opcoes[:familia_especifica] || "MODULO_ALTO"

    # Engenharia de triplo reforço segura em armários altos
    if h > 2000.0 && tipo_fixacao == "Duplo_Reforco"
      puts "🏗️ ConstrutorAlto: Injetando travessa central estrutural de segurança."

      z_meio_regua = (h / 2.0) - (larg_sarrafo / 2.0)
      recuo_fnd = opcoes_reaproveitadas[:fundo_recuado]
      pos_y_fundo = d - recuo_fnd - esp_fnd
      y_travessa = pos_y_fundo + esp_fnd
      larg_interna = w - (esp * 2)
      
      # 🚀 VALIDAÇÃO DE SEGURANÇA: Evita que a prateleira interna envergue sem divisória
      if larg_interna > (restricoes[:largura_max_vao_livre] || 900.0)
        puts "🚨 ALERTA DE ENGENHARIA: Vão interno de #{larg_interna}mm exige divisória vertical para evitar flecha!"
      end

      nome_trav_c = nom[:travessa_central_reforco] || "Travessa Central Reforco"
      regua_central = Peca.new(modulo.id_modulo, :travessa_central_reforco, nome_trav_c, larg_interna, esp, larg_sarrafo)
      regua_central.posicao_relativa = { pos_x: esp, pos_y: y_travessa, pos_z: z_meio_regua }
      modulo.adicionar_peca(regua_central)

      lat_esq = modulo.pecas.find { |p| p.categoria_industrial == :lateral_esquerda }
      lat_dir = modulo.pecas.find { |p| p.categoria_industrial == :lateral_direita }

      if lat_esq && lat_dir
        face_furo = (perfil[:tipo_montagem_caixa] == "Minifix") ? "FACE_INTERNA" : "FACE_EXTERNA"
        broca = (perfil[:tipo_montagem_caixa] == "Minifix") ? perfil[:usinagem][:broca_pino_minifix] : perfil[:usinagem][:broca_parafusos]
        
        y_centro_furo = y_travessa + (esp / 2.0)
        z_furo_centro = z_meio_regua + (larg_sarrafo / 3.5)

        lat_esq.adicionar_furo(y_centro_furo, z_furo_centro, broca, esp, face_furo)
        lat_dir.adicionar_furo(y_centro_furo, z_furo_centro, broca, esp, face_furo)
      end
    end

    return modulo
  end
end