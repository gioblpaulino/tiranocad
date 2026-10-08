# ==============================================================================
# MOTOR DE MÁQUINA: IA DE USINAGEM E FURAÇÃO (Regras/ConstrutorUsinagens.rb)
# ==============================================================================

class ConstrutorUsinagens
 
  def self.obter_recuo_frente(perfil)
      perfil.dig(:usinagem, :recuo_furo_frontal) || 
        perfil.dig(:usinagem, :recuo_furo_padrao) || 32.0
  end

  def self.obter_recuo_tras(perfil)
    perfil.dig(:usinagem, :recuo_furo_traseiro) || 
      perfil.dig(:usinagem, :recuo_furo_padrao) || 32.0
  end

  # ==========================================================================
  # ENCONTRO: LATERAL PASSANTE (A lateral fura a base)
  # ==========================================================================
  def self.fixar_lateral_passante(lat, base, lado, perfil)
    y_frente = obter_recuo_frente(perfil)
    y_tras   = base.dimensoes[:y] - obter_recuo_tras(perfil)
    z_furo_lat = base.posicao_relativa[:pos_z] + (base.dimensoes[:z] / 2.0)
  
    esp_mdf = perfil[:espessura_mdf] || 15.0
    tipo_montagem = perfil[:tipo_montagem_caixa] || "Parafuso_Soberbo"

    if tipo_montagem == "Minifix"
      x_tambor = (lado == :esquerda) ? 34.0 : (base.dimensoes[:x] - 34.0)
      base.adicionar_furo(x_tambor, y_frente, 15.0, perfil[:usinagem][:prof_tambor_minifix], "FACE_SUPERIOR")
      base.adicionar_furo(x_tambor, y_tras, 15.0, perfil[:usinagem][:prof_tambor_minifix], "FACE_SUPERIOR")
    
      lat.adicionar_furo(y_frente, z_furo_lat, perfil[:usinagem][:broca_pino_minifix], esp_mdf, "FACE_INTERNA")
      lat.adicionar_furo(y_tras, z_furo_lat, perfil[:usinagem][:broca_pino_minifix], esp_mdf, "FACE_INTERNA")
    else
      # Parafuso Padrão Soberbo Passante
      broca = perfil[:usinagem][:broca_parafusos] || 4.5
      lat.adicionar_furo(y_frente, z_furo_lat, broca, esp_mdf, "FACE_EXTERNA")
      lat.adicionar_furo(y_tras, z_furo_lat, broca, esp_mdf, "FACE_EXTERNA")
    end
  end

  # ==========================================================================
  # ENCONTRO: BASE PASSANTE (A base fura a lateral por baixo)
  # ==========================================================================
  def self.fixar_base_passante(base, lat, lado, w_total, perfil)
    y_frente = obter_recuo_frente(perfil)
    y_tras   = base.dimensoes[:y] - obter_recuo_tras(perfil)
    esp_mdf  = perfil[:espessura_mdf] || 15.0
  
    x_furo_base = (lado == :esquerda) ? (esp_mdf / 2.0) : (w_total - (esp_mdf / 2.0))
    tipo_montagem = perfil[:tipo_montagem_caixa] || "Parafuso_Soberbo"

    if tipo_montagem == "Minifix"
      z_tambor = 34.0
      lat.adicionar_furo(y_frente, z_tambor, 15.0, perfil[:usinagem][:prof_tambor_minifix], "FACE_INTERNA")
      lat.adicionar_furo(y_tras, z_tambor, 15.0, perfil[:usinagem][:prof_tambor_minifix], "FACE_INTERNA")

      base.adicionar_furo(x_furo_base, y_frente, perfil[:usinagem][:broca_pino_minifix], esp_mdf, "FACE_SUPERIOR")
      base.adicionar_furo(x_furo_base, y_tras, perfil[:usinagem][:broca_pino_minifix], esp_mdf, "FACE_SUPERIOR")
    else
      # Parafuso Soberbo
      broca = perfil[:usinagem][:broca_parafusos] || 4.5
      base.adicionar_furo(x_furo_base, y_frente, broca, esp_mdf, "FACE_SUPERIOR")
      base.adicionar_furo(x_furo_base, y_tras, broca, esp_mdf, "FACE_SUPERIOR")
    end
  end

  # ==========================================================================
  # ENCONTRO: LATERAIS COM SARRAFOS (Frente e Costas)
  # ==========================================================================
  def self.usinagem_sarrafos(lat, h_lats, d, esp_mdf, opcoes, perfil)
    larg_sarrafo = perfil[:geometria][:largura_sarrafo] || 70.0
    alt_cava     = perfil[:geometria][:altura_cava] || 35.0
    
    recuo_fnd = opcoes[:fundo] ? (perfil[:recuo_fundo] || 15.0) : 0.0
    esp_fnd   = perfil[:espessura_fundo] || 6.0
    tipo_montagem = perfil[:tipo_montagem_caixa] || "Parafuso_Soberbo"
  
    # 1. SARRAFO FRONTAL (Centralizado na largura do sarrafo)
    if opcoes[:cava]
      y_batente = esp_mdf / 2.0
      z_batente = h_lats - (alt_cava / 2.0)
      lat.adicionar_furo(y_batente, z_batente, perfil[:usinagem][:broca_parafusos], esp_mdf, "FACE_EXTERNA")
    
      y_reforco = esp_mdf + (larg_sarrafo / 2.0)
      z_reforco = h_lats - (esp_mdf / 2.0)
      lat.adicionar_furo(y_reforco, z_reforco, perfil[:usinagem][:broca_parafusos], esp_mdf, "FACE_EXTERNA")
    else
      # 🚀 CORREÇÃO: Centraliza o furo na largura do sarrafo frontal (ex: 70mm / 2 = 35mm)
      y_front = larg_sarrafo / 2.0
      z_front = h_lats - (esp_mdf / 2.0)
    
      face_furo = (tipo_montagem == "Minifix") ? "FACE_INTERNA" : "FACE_EXTERNA"
      broca = (tipo_montagem == "Minifix") ? perfil[:usinagem][:broca_pino_minifix] : perfil[:usinagem][:broca_parafusos]
      lat.adicionar_furo(y_front, z_front, broca, esp_mdf, face_furo)
    end
  
    # 2. SARRAFO TRASEIRO (Estrutura de Fechamento)
    if opcoes[:tipo_sarrafo_tras] && opcoes[:tipo_sarrafo_tras] != "nenhum"
      if opcoes[:tipo_sarrafo_tras] == "em_pe"
        y_tras = d - recuo_fnd - (esp_mdf / 2.0)
        z_tras = h_lats - (larg_sarrafo / 2.0)
      else
        y_inicial_sarr = d - recuo_fnd - esp_fnd - larg_sarrafo
        y_inicial_sarr = d - larg_sarrafo if !opcoes[:fundo]
        y_tras = y_inicial_sarr + (larg_sarrafo / 2.0)
        z_tras = h_lats - (esp_mdf / 2.0)
      end
    
      face_furo = (tipo_montagem == "Minifix") ? "FACE_INTERNA" : "FACE_EXTERNA"
      broca = (tipo_montagem == "Minifix") ? perfil[:usinagem][:broca_pino_minifix] : perfil[:usinagem][:broca_parafusos]
      lat.adicionar_furo(y_tras, z_tras, broca, esp_mdf, face_furo)
    end
  end
end