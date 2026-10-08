# ==============================================================================
# MOTOR DE REGRAS: CONSTRUTOR DE AÉREOS V6 (Regras/ConstrutorAereo.rb)
# Geometria Flexível Assegurada sem Vazamento de Escopo Paramétrico
# ==============================================================================
require_relative 'ConstrutorUsinagens'

class ConstrutorAereo
 
  def self.fabricar(nome, w, h, d, opcoes={})
    modulo = Modulo.new(nome, "MODULO_AEREO", w, h, d)
 
    perfil = opcoes[:perfil_objeto_custom] || GerenciadorPerfis.obter_perfil(opcoes[:nome_perfil_ativo] || "Padrao_Gemini")
    nom = perfil[:nomenclatura] || {}
 
    esp = (perfil[:espessura_mdf] || 15.0).to_f
    modulo.parametros_globais[:espessura_mdf] = esp

    esp_fnd = (modulo.parametros_globais[:espessura_fundo] || perfil[:espessura_fundo] || 6.0).to_f
    recuo_fnd = opcoes.fetch(:fundo_recuado, 15.0) 

    larg_sarrafo = perfil[:geometria][:largura_sarrafo] || 70.0
    prof_rasgo = perfil[:geometria][:prof_rasgo_fundo] || 6.0

    larg_interna = w - (esp * 2)

    # 2. INICIALIZAÇÃO E CÁLCULO ESTRITO DE TOPOLOGIA DE CAIXA PARA O AÉREO
    if opcoes[:montagem] == "Base Passante"
      w_base = w
      x_base = 0.0
      z_lats = esp
      h_lats = h - (esp * 2)
      larg_fundo = larg_interna + (prof_rasgo * 2)
      alt_fundo = h - (esp * 2) + (prof_rasgo * 2)
    else # Lateral Passante
      w_base = larg_interna
      x_base = esp
      z_lats = 0.0
      h_lats = h
      larg_fundo = larg_interna + (prof_rasgo * 2)
      alt_fundo = h + (prof_rasgo * 2)
    end
 
    z_teto = h - esp
 
    # Fundo Costa
    nome_fnd = nom[:fundo_costa] || "Fundo Costa"
    fundo = Peca.new(modulo.id_modulo, :fundo_costa, nome_fnd, larg_fundo, esp_fnd, alt_fundo)
    pos_y_fundo = d - recuo_fnd - esp_fnd
    fundo.posicao_relativa = { pos_x: esp - prof_rasgo, pos_y: pos_y_fundo, pos_z: (opcoes[:montagem] == "Base Passante" ? esp - prof_rasgo : 0.0 - prof_rasgo) }
    fundo.fita_borda = {}
    modulo.adicionar_peca(fundo)

    # ==========================================================================
    # 3. FABRICAÇÃO PARAMÉTRICA COM ISOLAMENTO DE CATEGORIAS E NOMES
    # ==========================================================================
    mat_caixa = opcoes[:material_caixaria] || "generico_branco_tx"
    mat_frente = opcoes[:material_frentes] || mat_caixa

    # Lateral Esquerda
    nome_lat_esq = nom[:lateral_esquerda] || "Lateral Esquerda"
    lat_esq = Peca.new(modulo.id_modulo, :lateral_esquerda, nome_lat_esq, esp, d, h_lats)
    lat_esq.posicao_relativa = { pos_x: 0.0, pos_y: 0.0, pos_z: z_lats }
    lat_esq.definir_material!(mat_caixa)
    lat_esq.fita_borda = { frontal: mat_frente }
    modulo.adicionar_peca(lat_esq)

    # Lateral Direita
    nome_lat_dir = nom[:lateral_direita] || "Lateral Direita"
    lat_dir = Peca.new(modulo.id_modulo, :lateral_direita, nome_lat_dir, esp, d, h_lats)
    lat_dir.posicao_relativa = { pos_x: w - esp, pos_y: 0.0, pos_z: z_lats }
    lat_dir.definir_material!(mat_caixa)
    lat_dir.fita_borda = { frontal: mat_frente }
    modulo.adicionar_peca(lat_dir)

    # Base Inferior
    nome_base = nom[:base_inferior] || "Base Inferior"
    base_inf = Peca.new(modulo.id_modulo, :base_inferior, nome_base, w_base, d, esp)
    base_inf.posicao_relativa = { pos_x: x_base, pos_y: 0.0, pos_z: 0.0 }
    base_inf.definir_material!(mat_caixa)
    base_inf.fita_borda = { frontal: mat_frente }
    modulo.adicionar_peca(base_inf)

    # Base Superior / Teto
    nome_teto = nom[:base_superior] || "Base Superior / Teto"
    base_sup = Peca.new(modulo.id_modulo, :base_superior, nome_teto, w_base, d, esp)
    base_sup.posicao_relativa = { pos_x: x_base, pos_y: 0.0, pos_z: z_teto }
    base_sup.definir_material!(mat_caixa)
    base_sup.fita_borda = { frontal: mat_frente }
    modulo.adicionar_peca(base_sup)

    # ==========================================================================
    # 4. TRAVESSAS TRASEIRAS DE FIXAÇÃO DE AÉREO
    # ==========================================================================
    y_travessa = pos_y_fundo + esp_fnd 
    tipo_fixacao = opcoes.fetch(:fixacao, "Mao_Amiga")

    case tipo_fixacao
    when "Mao_Amiga"
      nome_regua_m = nom[:regua_movel_45] || "Regua Movel 45"
      regua_movel = Peca.new(modulo.id_modulo, :regua_movel_45, nome_regua_m, larg_interna, esp, larg_sarrafo)
      regua_movel.posicao_relativa = { pos_x: esp, pos_y: y_travessa, pos_z: h - esp - larg_sarrafo }
      modulo.adicionar_peca(regua_movel)

      larg_regua_parede = larg_interna - 100.0
      x_regua_parede = esp + 50.0 
      nome_regua_p = nom[:regua_parede_45] || "Regua Parede 45"
      regua_parede = Peca.new(modulo.id_modulo, :regua_parede_45, nome_regua_p, larg_regua_parede, esp, larg_sarrafo)
      regua_parede.posicao_relativa = { pos_x: x_regua_parede, pos_y: y_travessa, pos_z: h - esp - larg_sarrafo * 2 }
      regua_parede.fita_borda = {}
      modulo.adicionar_peca(regua_parede)

    when "Duplo_Reforco"
      nome_trav_s = nom[:travessa_sup_reforco] || "Travessa Sup Reforco"
      travessa_sup = Peca.new(modulo.id_modulo, :travessa_sup_reforco, nome_trav_s, larg_interna, esp, larg_sarrafo)
      travessa_sup.posicao_relativa = { pos_x: esp, pos_y: y_travessa, pos_z: h - esp - larg_sarrafo }
      travessa_sup.fita_borda = {}
      modulo.adicionar_peca(travessa_sup)

      nome_trav_i = nom[:travessa_inf_reforco] || "Travessa Inf Reforco"
      travessa_inf = Peca.new(modulo.id_modulo, :travessa_inf_reforco, nome_trav_i, larg_interna, esp, larg_sarrafo)
      travessa_inf.posicao_relativa = { pos_x: esp, pos_y: y_travessa, pos_z: esp }
      travessa_inf.fita_borda = {}
      modulo.adicionar_peca(travessa_inf)

    when "Bucha_Simples"
      nome_trav_u = nom[:travessa_superior] || "Travessa Superior"
      travessa_sup = Peca.new(modulo.id_modulo, :travessa_superior, nome_trav_u, larg_interna, esp, larg_sarrafo)
      travessa_sup.posicao_relativa = { pos_x: esp, pos_y: y_travessa, pos_z: h - esp - larg_sarrafo }
      travessa_sup.fita_borda = {}
      modulo.adicionar_peca(travessa_sup)
    end

    # ==========================================================================
    # 5. INDUSTRIAL CNC: DISPARO DE USINAGENS ASSEGURADAS
    # ==========================================================================
    if defined?(ConstrutorUsinagens)
      if opcoes[:montagem] == "Lateral Passante"
        ConstrutorUsinagens.fixar_lateral_passante(lat_esq, base_inf, :esquerda, perfil)
        ConstrutorUsinagens.fixar_lateral_passante(lat_dir, base_inf, :direita, perfil)
        ConstrutorUsinagens.fixar_lateral_passante(lat_esq, base_sup, :esquerda, perfil)
        ConstrutorUsinagens.fixar_lateral_passante(lat_dir, base_sup, :direita, perfil)
      else
        ConstrutorUsinagens.fixar_base_passante(base_inf, lat_esq, :esquerda, w, perfil)
        ConstrutorUsinagens.fixar_base_passante(base_inf, lat_dir, :direita, w, perfil)
        ConstrutorUsinagens.fixar_base_passante(base_sup, lat_esq, :esquerda, w, perfil)
        ConstrutorUsinagens.fixar_base_passante(base_sup, lat_dir, :direita, w, perfil)
      end

      face_furo = (perfil[:tipo_montagem_caixa] == "Minifix") ? "FACE_INTERNA" : "FACE_EXTERNA"
      broca = (perfil[:tipo_montagem_caixa] == "Minifix") ? perfil[:usinagem][:broca_pino_minifix] : perfil[:usinagem][:broca_parafusos]
      y_centro_regua = y_travessa + (esp / 2.0)

      case tipo_fixacao
      when "Mao_Amiga", "Bucha_Simples"
        z_centro_superior = h - (esp * 2) - (larg_sarrafo / 2.0)
        lat_esq.adicionar_furo(y_centro_regua, z_centro_superior, broca, esp, face_furo)
        lat_dir.adicionar_furo(y_centro_regua, z_centro_superior, broca, esp, face_furo)

      when "Duplo_Reforco"
        z_centro_superior = h - (esp * 2) - (larg_sarrafo / 2.0)
        lat_esq.adicionar_furo(y_centro_regua, z_centro_superior, broca, esp, face_furo)
        lat_dir.adicionar_furo(y_centro_regua, z_centro_superior, broca, esp, face_furo)

        z_centro_inferior = larg_sarrafo / 2.0
        lat_esq.adicionar_furo(y_centro_regua, z_centro_inferior, broca, esp, face_furo)
        lat_dir.adicionar_furo(y_centro_regua, z_centro_inferior, broca, esp, face_furo)
      end
    end

    return modulo
  end
end