# ==============================================================================
# MOTOR DE REGRAS: CONSTRUTOR DE INFERIORES V4 (Regras/ConstrutorInferior.rb)
# Arquitetura 100% Data-Driven Desacoplada e Isolada por Categorias
# ==============================================================================
require_relative 'ConstrutorUsinagens'

class ConstrutorInferior
 
  def self.fabricar(nome, w, h, d, opcoes={})
    modulo = Modulo.new(nome, "MODULO_INFERIOR", w, h, d)
    
    # 1. RESOLUÇÃO DO PERFIL E DA ESPESSURA DINÂMICA
    perfil = opcoes[:perfil_objeto_custom] || GerenciadorPerfis.obter_perfil(opcoes[:nome_perfil_ativo] || "Padrao_Gemini")
    nom = perfil[:nomenclatura] || {}

    esp = (perfil[:espessura_mdf] || 15.0).to_f
    modulo.parametros_globais[:espessura_mdf] = esp

    esp_fnd = (modulo.parametros_globais[:espessura_fundo] || perfil[:espessura_fundo] || 6.0).to_f
    recuo_fnd = opcoes[:recuo_fundo_custom] || (opcoes[:fundo] ? perfil[:recuo_fundo] : 0.0)

    larg_sarrafo = perfil[:geometria][:largura_sarrafo] || 70.0
    alt_cava = perfil[:geometria][:altura_cava] || 35.0
    prof_rasgo = perfil[:geometria][:prof_rasgo_fundo] || 6.0

    larg_interna = w - (esp * 2)
    x_miolo = esp 

    # 2. TOPOLOGIA DE MONTAGEM DA CAIXA
    if opcoes[:montagem] == "Base Passante"
      w_base = w
      x_base = 0.0 
      z_lats = esp
      h_lats = h - esp
    else
      w_base = larg_interna
      x_base = esp 
      z_lats = 0.0
      h_lats = h
    end

    # 3. FABRICAÇÃO PARAMÉTRICA COM ISOLAMENTO DE CATEGORIAS
    mat_caixa = opcoes[:material_caixaria] || "generico_branco_tx"

    # Lateral Esquerda
    nome_lat_esq = nom[:lateral_esquerda] || "Lateral Esquerda"
    lat_esq = Peca.new(modulo.id_modulo, :lateral_esquerda, nome_lat_esq, esp, d, h_lats)
    lat_esq.posicao_relativa = { pos_x: 0.0, pos_y: 0.0, pos_z: z_lats }
    lat_esq.definir_material!(mat_caixa)
    lat_esq.fita_borda = { frontal: mat_caixa }
    modulo.adicionar_peca(lat_esq)

    # Lateral Direita
    nome_lat_dir = nom[:lateral_direita] || "Lateral Direita"
    lat_dir = Peca.new(modulo.id_modulo, :lateral_direita, nome_lat_dir, esp, d, h_lats)
    lat_dir.posicao_relativa = { pos_x: w - esp, pos_y: 0.0, pos_z: z_lats }
    lat_dir.definir_material!(mat_caixa)
    lat_dir.fita_borda = { frontal: mat_caixa }
    modulo.adicionar_peca(lat_dir)

    # Base Inferior
    nome_base = nom[:base_inferior] || "Base Inferior"
    base_inf = Peca.new(modulo.id_modulo, :base_inferior, nome_base, w_base, d, esp)
    base_inf.posicao_relativa = { pos_x: x_base, pos_y: 0.0, pos_z: 0.0 }
    base_inf.definir_material!(mat_caixa)

    fitas_base = { frontal: mat_caixa }
    if opcoes[:montagem] == "Base Passante" && opcoes[:fita_laterais_base]
      fitas_base[:esquerda] = mat_caixa
      fitas_base[:direita] = mat_caixa
    end
    base_inf.fita_borda = fitas_base
    modulo.adicionar_peca(base_inf)

    # Fundo Traseiro Costa
    if opcoes[:fundo]
      larg_fundo = larg_interna + (prof_rasgo * 2)
      alt_fundo = h - esp + prof_rasgo 

      nome_fnd = nom[:fundo_costa] || "Fundo Costa"
      fundo = Peca.new(modulo.id_modulo, :fundo_costa, nome_fnd, larg_fundo, esp_fnd, alt_fundo)
      pos_y_fundo = d - recuo_fnd - esp_fnd
      fundo.posicao_relativa = { pos_x: x_miolo - prof_rasgo, pos_y: pos_y_fundo, pos_z: esp - prof_rasgo }
      fundo.fita_borda = {} 
      modulo.adicionar_peca(fundo)
    end

    # Fechamento Superior (Estrutura Convencional vs Sistema Cava)
    if opcoes[:cava]
      nome_batente = nom[:batente_cava] || "Batente Cava"
      batente_cava = Peca.new(modulo.id_modulo, :batente_cava, nome_batente, larg_interna, esp, alt_cava)
      batente_cava.posicao_relativa = { pos_x: x_miolo, pos_y: 0.0, pos_z: h - alt_cava }
      batente_cava.fita_borda = { superior: 1 } 
      modulo.adicionar_peca(batente_cava)
     
      nome_reforco = nom[:reforco_cava] || "Reforco Cava"
      reforco_cava = Peca.new(modulo.id_modulo, :reforco_cava, nome_reforco, larg_interna, larg_sarrafo, esp)
      reforco_cava.posicao_relativa = { pos_x: x_miolo, pos_y: esp, pos_z: h - esp }
      reforco_cava.fita_borda = { frontal: 1 } 
      modulo.adicionar_peca(reforco_cava)
    else
      nome_sarrafo_f = nom[:sarrafo_frontal] || "Sarrafo Frontal"
      sarr_front = Peca.new(modulo.id_modulo, :sarrafo_frontal, nome_sarrafo_f, larg_interna, larg_sarrafo, esp)
      sarr_front.posicao_relativa = { pos_x: x_miolo, pos_y: 0.0, pos_z: h - esp }
      sarr_front.fita_borda = { frontal: mat_caixa }
      modulo.adicionar_peca(sarr_front)
    end

    # Sarrafo de Amarração Traseiro
    if opcoes[:tipo_sarrafo_tras] && opcoes[:tipo_sarrafo_tras] != "nenhum"
      if opcoes[:tipo_sarrafo_tras] == "em_pe"
        nome_sarr_t = nom[:sarrafo_traseiro_em_pe] || "Sarrafo Traseiro em Pé"
        sarr_tras = Peca.new(modulo.id_modulo, :sarrafo_traseiro_em_pe, nome_sarr_t, larg_interna, esp, larg_sarrafo)
        sarr_tras.posicao_relativa = { pos_x: x_miolo, pos_y: d - esp, pos_z: h - larg_sarrafo }
      else
        nome_sarr_t = nom[:sarrafo_traseiro_deitado] || "Sarrafo Traseiro Deitado"
        sarr_tras = Peca.new(modulo.id_modulo, :sarrafo_traseiro_deitado, nome_sarr_t, larg_interna, larg_sarrafo, esp)
        y_sarr_tras = d - recuo_fnd - esp_fnd - larg_sarrafo
        y_sarr_tras = d - larg_sarrafo if !opcoes[:fundo]
        sarr_tras.posicao_relativa = { pos_x: x_miolo, pos_y: y_sarr_tras, pos_z: h - esp }
      end
      sarr_tras.fita_borda = {} 
      modulo.adicionar_peca(sarr_tras)
    end

    # ==========================================================================
    # 5. DISPARO DAS USINAGENS DE ESTRUTURAÇÃO DA CAIXA
    # ==========================================================================
    if defined?(ConstrutorUsinagens)
      if opcoes[:montagem] == "Lateral Passante"
        # O motor de usinagem continuará recebendo os objetos limpos independentemente dos nomes comerciais
        # que eles ganharam das marcenarias
        if ConstrutorUsinagens.respond_to?(:fixar_lateral_passante)
          ConstrutorUsinagens.fixar_lateral_passante(lat_esq, base_inf, :esquerda, perfil)
          ConstrutorUsinagens.fixar_lateral_passante(lat_dir, base_inf, :direita, perfil)
        end
      else
        if ConstrutorUsinagens.respond_to?(:fixar_base_passante)
          ConstrutorUsinagens.fixar_base_passante(base_inf, lat_esq, :esquerda, w, perfil)
          ConstrutorUsinagens.fixar_base_passante(base_inf, lat_dir, :direita, w, perfil)
        end
      end

      if ConstrutorUsinagens.respond_to?(:usinagem_sarrafos)
        ConstrutorUsinagens.usinagem_sarrafos(lat_esq, h_lats, d, esp, opcoes, perfil)
        ConstrutorUsinagens.usinagem_sarrafos(lat_dir, h_lats, d, esp, opcoes, perfil)
      end
    
    end
    return modulo
  end
end