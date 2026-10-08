# ==============================================================================
# MOTOR DE REGRAS: CONSTRUTOR DE FRENTES GEOMÉTRICO V3 (Regras/ConstrutorFrentes.rb)
# ==============================================================================
require 'securerandom'

class ConstrutorFrentes

  def self.adicionar_portas_giro(modulo, no_espacial, qtd_portas)
    perfil = GerenciadorPerfis.obter_perfil(modulo.parametros_globais[:perfil_montagem] || "Padrao_Gemini")
    nom = perfil[:nomenclatura] || {}

    esp = modulo.parametros_globais[:espessura_mdf]
    w_total = modulo.dimensoes_totais[:largura_x]
    h_total = modulo.dimensoes_totais[:altura_y]

    # Resgata o material de frentes selecionado na UI (com fallback de segurança)
    mat_frente = modulo.parametros_globais[:material_frentes] || "generico_branco_tx"
    
    gap_int = modulo.parametros_globais[:gap_int]
    gap_sup = modulo.parametros_globais[:gap_sup]
    gap_inf = modulo.parametros_globais[:gap_inf]
    gap_lat = modulo.parametros_globais[:gap_lat]

    is_left_edge = (no_espacial.x <= esp + 0.1)
    is_right_edge = ((no_espacial.x + no_espacial.w) >= (w_total - esp - 0.1))
    is_bottom_edge = (no_espacial.z <= esp + 0.1)
    is_top_edge = ((no_espacial.z + no_espacial.h) >= (h_total - esp - 0.1))

    exp_esq = is_left_edge ? esp : (esp / 2.0)
    exp_dir = is_right_edge ? esp : (esp / 2.0)
    exp_inf = is_bottom_edge ? esp : (esp / 2.0)
    exp_sup = is_top_edge ? esp : (esp / 2.0)

    gap_esq = is_left_edge ? gap_lat : (gap_int / 2.0)
    gap_dir = is_right_edge ? gap_lat : (gap_int / 2.0)
    gap_inf_real = is_bottom_edge ? gap_inf : (gap_int / 2.0)
    gap_sup_real = is_top_edge ? gap_sup : (gap_int / 2.0)

    w_area = no_espacial.w + exp_esq + exp_dir - gap_esq - gap_dir
    h_area = no_espacial.h + exp_inf + exp_sup - gap_inf_real - gap_sup_real
    
    x_inicial = no_espacial.x - exp_esq + gap_esq
    z_inicial = no_espacial.z - exp_inf + gap_inf_real

    w_porta = (w_area - (gap_int * (qtd_portas - 1))) / qtd_portas.to_f
    h_porta = h_area
    
    return if w_porta < 50.0 || h_porta < 50.0 

      id_vinculo_grupo_portas = SecureRandom.uuid

      # Resgata a preferência do usuário gravada no nó (padrão: :esquerda)
      sentido_definido = (no_espacial.conteudo["sentido_porta"] || "esquerda").to_sym
      
      qtd_portas.times do |i|
        # 🚀 INTELIGÊNCIA DE ABERTURA: Se for porta única (qtd == 1), usa o sentido escolhido
        if qtd_portas == 1
          sentido_eixo = sentido_definido
        else
          sentido_eixo = (i == 0) ? :esquerda : :direita
        end
      
        categoria_p = "porta_giro_#{sentido_eixo}".to_sym
        
        prefixo_nome = sentido_eixo == :esquerda ? (nom[:porta_esquerda] || "Porta Esq.") : (nom[:porta_direita] || "Porta Dir.")
        nome_comercial = "#{prefixo_nome} #{i+1}"
      
        porta = Peca.new(modulo.id_modulo, categoria_p, nome_comercial, w_porta, esp, h_porta)
        
        # Atribuição dinâmica do material de frentes e fitas de borda
        porta.definir_material!(mat_frente)
        porta.fita_borda = { frontal: mat_frente, esquerda: mat_frente, direita: mat_frente, superior: mat_frente, inferior: mat_frente }
        
        porta.id_vinculo_structure = id_vinculo_grupo_portas
        
        px = x_inicial + (i * (w_porta + gap_int))
        py = -esp 
        pz = z_inicial
      
        porta.posicao_relativa = { pos_x: px, pos_y: py, pos_z: pz }
        modulo.adicionar_peca(porta)
      end
  end

  def self.adicionar_gaveteiro(modulo, no_espacial, qtd_gavetas, opcoes_gaveta={})
    perfil = GerenciadorPerfis.obter_perfil(modulo.parametros_globais[:perfil_montagem] || "Padrao_Gemini")
    nom = perfil[:nomenclatura] || {}

    esp = modulo.parametros_globais[:espessura_mdf]
    prof_livre = modulo.dimensoes_totais[:profundidade_z] - 35.0
    return if prof_livre < 250.0

    w_total = modulo.dimensoes_totais[:largura_x]
    h_total = modulo.dimensoes_totais[:altura_y]

    mat_frente = modulo.parametros_globais[:material_frentes] || "arauco_louro_freijo"
    
    gap_int = modulo.parametros_globais[:gap_int]
    gap_sup = modulo.parametros_globais[:gap_sup]
    gap_inf = modulo.parametros_globais[:gap_inf]
    gap_lat = modulo.parametros_globais[:gap_lat]

    is_left_edge = (no_espacial.x <= esp + 0.1)
    is_right_edge = ((no_espacial.x + no_espacial.w) >= (w_total - esp - 0.1))
    is_bottom_edge = (no_espacial.z <= esp + 0.1)
    is_top_edge = ((no_espacial.z + no_espacial.h) >= (h_total - esp - 0.1))

    exp_esq = is_left_edge ? esp : (esp / 2.0)
    exp_dir = is_right_edge ? esp : (esp / 2.0)
    exp_inf = is_bottom_edge ? esp : (esp / 2.0)
    exp_sup = is_top_edge ? esp : (esp / 2.0)

    gap_esq = is_left_edge ? gap_lat : (gap_int / 2.0)
    gap_dir = is_right_edge ? gap_lat : (gap_int / 2.0)
    gap_inf_real = is_bottom_edge ? gap_inf : (gap_int / 2.0)
    gap_sup_real = is_top_edge ? gap_sup : (gap_int / 2.0)

    w_area = no_espacial.w + exp_esq + exp_dir - gap_esq - gap_dir
    h_area = no_espacial.h + exp_inf + exp_sup - gap_inf_real - gap_sup_real
    
    x_inicial = no_espacial.x - exp_esq + gap_esq
    z_acumulado = no_espacial.z - exp_inf + gap_inf_real
    w_frente = w_area

    destaque_ativo = no_espacial.conteudo["gaveta_destaque_ativa"] == true
    h_destaque_alvo = (no_espacial.conteudo["altura_gaveta_destaque"] || 300.0).to_f

    qtd_gavetas.times do |i|
      id_vinculo_gaveta = SecureRandom.uuid
      
      if destaque_ativo && i == 0
        h_frente = h_destaque_alvo - gap_int
        categoria_f = :frente_gavetaao
        nome_comercial_f = nom[:frente_gavetao] || "Frente Gavetão"
      else
        categoria_f = :frente_gaveta
        nome_comercial_f = (nom[:frente_gaveta] || "Frente Gaveta") + " #{i+1}"
        if destaque_ativo && qtd_gavetas > 1
          h_sobra_util = h_area - h_destaque_alvo
          h_frente = (h_sobra_util - (gap_int * (qtd_gavetas - 2))) / (qtd_gavetas - 1).to_f
        else
          h_frente = (h_area - (gap_int * (qtd_gavetas - 1))) / qtd_gavetas.to_f
        end
      end

      frente = Peca.new(modulo.id_modulo, categoria_f, nome_comercial_f, w_frente, esp, h_frente)
      
      # Atribuição dinâmica do material de frentes e fitas de borda
      frente.definir_material!(mat_frente)
      frente.fita_borda = { frontal: mat_frente, esquerda: mat_frente, direita: mat_frente, superior: mat_frente, inferior: mat_frente }
      
      frente.id_vinculo_structure = id_vinculo_gaveta
      frente.posicao_relativa = { pos_x: x_inicial, pos_y: -esp, pos_z: z_acumulado }
      modulo.adicionar_peca(frente)

      if defined?(ConstrutorGavetas)
        ConstrutorGavetas.fabricar_caixote(modulo, id_vinculo_gaveta, no_espacial.w, h_frente, prof_livre, z_acumulado, no_espacial.x, opcoes_gaveta) 
      end
      z_acumulado += (h_frente + gap_int)
    end
  end

  def self.adicionar_sapateira_deslizante(modulo, no_espacial, qtd_sapateiras)
    esp = modulo.parametros_globais[:espessura_mdf] || 15.0
    config_no = (no_espacial.conteudo || {}).transform_keys(&:to_s)
    
    # Resgate das dimensões do vão livre
    afast_esq = cfg_val(config_no, "afast_esq", 50.0)
    afast_dir = cfg_val(config_no, "afast_dir", 50.0)
    recuo_front_afastador = cfg_val(config_no, "afast_recuo_front", 50.0)
    recuo_tras_afastador = cfg_val(config_no, "afast_recuo_tras", 21.0)
    larg_reguete = cfg_val(config_no, "afast_larg_regua", 60.0)
    
    gap_mao_superior = cfg_val(config_no, "gav_int_gap_mao", 30.0)
    gap_inf_base_especial = cfg_val(config_no, "gav_int_gap_inf_base", 15.0)
    gap_int = modulo.parametros_globais[:gap_int] || 4.0

    w_vao_util = no_espacial.w - afast_esq - afast_dir
    x_interno_vao = no_espacial.x + afast_esq
    prof_movel = modulo.dimensoes_totais[:profundidade_z]
    prof_livre_interna = prof_movel - recuo_front_afastador - recuo_tras_afastador
    
    h_area = no_espacial.h
    h_util = h_area - gap_inf_base_especial
    h_passo = (h_util - (gap_int * (qtd_sapateiras - 1))) / qtd_sapateiras.to_f

    # 1. Construção dos Afastadores Laterais (se configurados na UI)
    construir_afastadores_laterais(modulo, no_espacial, afast_esq, afast_dir, recuo_front_afastador, recuo_tras_afastador, larg_reguete, h_area)

    # 2. Distribuição das Sapateiras no Vão
    z_acumulado = no_espacial.z + gap_inf_base_especial

    qtd_sapateiras.times do |i|
      id_vinculo = SecureRandom.uuid

      if defined?(ConstrutorGavetas) && ConstrutorGavetas.respond_to?(:fabricar_caixote_sapateira)
        ConstrutorGavetas.fabricar_caixote_sapateira(
          modulo, 
          id_vinculo, 
          w_vao_util, 
          prof_livre_interna, 
          z_acumulado, 
          x_interno_vao, 
          { recuo_frente: recuo_front_afastador }
        )
      end

      z_acumulado += (h_passo + gap_int)
    end
  end

  # Método auxiliar estático para resgate limpo de valores de configuração
  def self.cfg_val(hash, chave, padrao)
    (hash.fetch(chave, padrao)).to_f
  end

  def self.adicionar_porta_tempero(modulo, no_espacial)
    perfil = GerenciadorPerfis.obter_perfil(modulo.parametros_globais[:perfil_montagem] || "Padrao_Gemini")
    nom = perfil[:nomenclatura] || {}

    esp = modulo.parametros_globais[:espessura_mdf]
    prof_livre = modulo.dimensoes_totais[:profundidade_z] - 35.0
    return if prof_livre < 250.0

    w_total = modulo.dimensoes_totais[:largura_x]
    h_total = modulo.dimensoes_totais[:altura_y]

    mat_frente = modulo.parametros_globais[:material_frentes] || "arauco_louro_freijo"
    
    gap_lat = modulo.parametros_globais[:gap_lat]
    gap_sup = modulo.parametros_globais[:gap_sup]
    gap_inf = modulo.parametros_globais[:gap_inf]
    gap_int = modulo.parametros_globais[:gap_int]

    is_left_edge = (no_espacial.x <= esp + 0.1)
    is_right_edge = ((no_espacial.x + no_espacial.w) >= (w_total - esp - 0.1))
    is_bottom_edge = (no_espacial.z <= esp + 0.1)
    is_top_edge = ((no_espacial.z + no_espacial.h) >= (h_total - esp - 0.1))

    exp_esq = is_left_edge ? esp : (esp / 2.0)
    exp_dir = is_right_edge ? esp : (esp / 2.0)
    exp_inf = is_bottom_edge ? esp : (esp / 2.0)
    exp_sup = is_top_edge ? esp : (esp / 2.0)

    gap_esq = is_left_edge ? gap_lat : (gap_int / 2.0)
    gap_dir = is_right_edge ? gap_lat : (gap_int / 2.0)
    gap_inf_real = is_bottom_edge ? gap_inf : (gap_int / 2.0)
    gap_sup_real = is_top_edge ? gap_sup : (gap_int / 2.0)

    w_frente = no_espacial.w + exp_esq + exp_dir - gap_esq - gap_dir
    h_frente = no_espacial.h + exp_inf + exp_sup - gap_inf_real - gap_sup_real
    
    x_inicial = no_espacial.x - exp_esq + gap_esq
    z_inicial = no_espacial.z - exp_inf + gap_inf_real

    id_vinculo_tempero = SecureRandom.uuid
    nome_frente_t = nom[:frente_porta_tempero] || "Frente Porta Tempero"
    
    frente = Peca.new(modulo.id_modulo, :frente_porta_tempero, nome_frente_t, w_frente, esp, h_frente)
    
    # Atribuição dinâmica do material de frentes e fitas de borda
    frente.definir_material!(mat_frente)
    frente.fita_borda = { frontal: mat_frente, esquerda: mat_frente, direita: mat_frente, superior: mat_frente, inferior: mat_frente }
    
    frente.id_vinculo_structure = id_vinculo_tempero
    frente.posicao_relativa = { pos_x: x_inicial, pos_y: -esp, pos_z: z_inicial }
    modulo.adicionar_peca(frente)

    if defined?(ConstrutorPortaTempero)
      ConstrutorPortaTempero.fabricar(modulo, id_vinculo_tempero, no_espacial.w, no_espacial.h, prof_livre, z_inicial, no_espacial.x)
    end
  end

  def self.construir_afastadores_laterais(modulo, no_espacial, afast_esq, afast_dir, recuo_front, recuo_tras, larg_regua, h_area)
    esp = modulo.parametros_globais[:espessura_mdf] || 15.0
    mat_frente = modulo.parametros_globais[:material_frentes] || "arauco_louro_freijo"
    prof_movel = modulo.dimensoes_totais[:profundidade_z]
    prof_central = prof_movel - recuo_front - recuo_tras - (esp * 2)

    if prof_central < 100.0
      prof_central = 100.0
    end

    # --- AFASTADOR ESQUERDO ---
    if afast_esq > 0
      # 1. Ripa Frontal
      reg_fr_esq = Peca.new(modulo.id_modulo, :afastador_interno, "Ripa Frontal Afast. Esq.", larg_regua, esp, h_area)
      reg_fr_esq.posicao_relativa = { pos_x: no_espacial.x, pos_y: recuo_front, pos_z: no_espacial.z }
      reg_fr_esq.fita_borda = { direita: mat_frente }
      modulo.adicionar_peca(reg_fr_esq)

      # 2. Suporte Central
      suporte_esq = Peca.new(modulo.id_modulo, :afastador_interno, "Suporte Corredica Esq.", esp, prof_central, h_area)
      suporte_esq.posicao_relativa = { pos_x: no_espacial.x + larg_regua - esp, pos_y: recuo_front + esp, pos_z: no_espacial.z }
      suporte_esq.fita_borda = {}
      modulo.adicionar_peca(suporte_esq)

      # 3. Ripa Traseira
      reg_tr_esq = Peca.new(modulo.id_modulo, :afastador_interno, "Ripa Tras Afast. Esq.", larg_regua, esp, h_area)
      pos_y_tr_esq = prof_movel - recuo_tras - esp
      reg_tr_esq.posicao_relativa = { pos_x: no_espacial.x, pos_y: pos_y_tr_esq, pos_z: no_espacial.z }
      reg_tr_esq.fita_borda = { direita: mat_frente }
      modulo.adicionar_peca(reg_tr_esq)
    end

    # --- AFASTADOR DIREITO ---
    if afast_dir > 0
      x_dir = no_espacial.x + no_espacial.w - larg_regua

      # 1. Ripa Frontal
      reg_fr_dir = Peca.new(modulo.id_modulo, :afastador_interno, "Ripa Frontal Afast. Dir.", larg_regua, esp, h_area)
      reg_fr_dir.posicao_relativa = { pos_x: x_dir, pos_y: recuo_front, pos_z: no_espacial.z }
      reg_fr_dir.fita_borda = { esquerda: mat_frente }
      modulo.adicionar_peca(reg_fr_dir)

      # 2. Suporte Central
      suporte_dir = Peca.new(modulo.id_modulo, :afastador_interno, "Suporte Corredica Dir.", esp, prof_central, h_area)
      suporte_dir.posicao_relativa = { pos_x: x_dir, pos_y: recuo_front + esp, pos_z: no_espacial.z }
      suporte_dir.fita_borda = {}
      modulo.adicionar_peca(suporte_dir)

      # 3. Ripa Traseira
      reg_tr_dir = Peca.new(modulo.id_modulo, :afastador_interno, "Ripa Tras Afast. Dir.", larg_regua, esp, h_area)
      pos_y_tr_dir = prof_movel - recuo_tras - esp
      reg_tr_dir.posicao_relativa = { pos_x: x_dir, pos_y: pos_y_tr_dir, pos_z: no_espacial.z }
      reg_tr_dir.fita_borda = { esquerda: mat_frente }
      modulo.adicionar_peca(reg_tr_dir)
    end
  end
  
  # ========================================================================
  # 🚀 INTERFACE INDUSTRIAL: GAVETEIROS E SAPATEIRAS INTERNAS PARAMÉTRICAS
  # ========================================================================
  def self.adicionar_gaveteiro_interno(modulo, no_espacial, qtd_gavetas)
    esp = modulo.parametros_globais[:espessura_mdf] || 15.0
    
    # Suporte a leitura flexível de Hash (Símbolos ou Strings)
    config_no = (no_espacial.conteudo || {}).transform_keys(&:to_s)
    
    mat_frente = modulo.parametros_globais[:material_frentes] || "arauco_louro_freijo"

    # 1. Resgate do Perfil da Marcenaria para Fallbacks de Segurança
    perfil = GerenciadorPerfis.obter_perfil(modulo.parametros_globais[:perfil_montagem] || "Padrao_Gemini")
    geom_perfil = perfil[:geometria] || {}
    larg_regua_padrao = geom_perfil[:largura_regua_afastador] || 60.0

    # 2. Extração dos Parâmetros Dinâmicos Enviados pela Interface (UI)
    afast_esq             = (config_no.fetch("afast_esq") || 50.0).to_f
    afast_dir             = (config_no.fetch("afast_dir") || 50.0).to_f
    recuo_front_afastador = (config_no.fetch("afast_recuo_front") || 50.0).to_f
    recuo_tras_afastador  = (config_no.fetch("afast_recuo_tras") || 21.0).to_f
    larg_reguete          = (config_no.fetch("afast_larg_regua") || larg_regua_padrao).to_f
    
    gap_mao_superior      = (config_no.fetch("gav_int_gap_mao") || 30.0).to_f
    reducao_caixote_corpo = (config_no.fetch("gav_int_red_corpo") || 0.0).to_f
    gap_inf_base_especial = (config_no.fetch("gav_int_gap_inf_base") || 15.0).to_f
    gap_lateral_corredica = (config_no.fetch("gav_int_gap_lat_corredica") || 13.0).to_f

    # 3. Dimensionamento do Vão Interno e Profundidades
    w_vao_util = no_espacial.w - afast_esq - afast_dir
    x_interno_vao = no_espacial.x + afast_esq
    prof_movel = modulo.dimensoes_totais[:profundidade_z]
    prof_livre_interna = prof_movel - recuo_front_afastador - recuo_tras_afastador

    h_area = no_espacial.h
    gap_int = modulo.parametros_globais[:gap_int] || 4.0
    z_acumulado = no_espacial.z
    mat_frente = modulo.parametros_globais[:material_frentes] || "generico_branco_tx"

    # 4. Cálculo da Peça Central do Afastador (Sanduichada)
    prof_central = prof_movel - recuo_front_afastador - recuo_tras_afastador - esp * 2

    if prof_central < 100.0
      puts "⚠️ Erro de Engenharia: Profundidade do móvel é pequena demais para os recuos do afastador!"
      prof_central = 100.0
    end

    if afast_esq > 0
      # 1. Ripa Frontal
      reg_fr_esq = Peca.new(modulo.id_modulo, :afastador_interno, "Ripa Frontal Afast. Esq.", larg_reguete, esp, h_area)
      reg_fr_esq.posicao_relativa = { pos_x: no_espacial.x, pos_y: recuo_front_afastador, pos_z: no_espacial.z }
      reg_fr_esq.fita_borda = { direita: mat_frente }
      modulo.adicionar_peca(reg_fr_esq)

      # 2. Suporte Central
      suporte_esq = Peca.new(modulo.id_modulo, :afastador_interno, "Suporte Corredica Esq.", esp, prof_central, h_area)
      suporte_esq.posicao_relativa = { pos_x: no_espacial.x + larg_reguete - esp, pos_y: recuo_front_afastador + esp, pos_z: no_espacial.z }
      suporte_esq.fita_borda = {}
      modulo.adicionar_peca(suporte_esq)

      # 3. Ripa Traseira
      reg_tr_esq = Peca.new(modulo.id_modulo, :afastador_interno, "Ripa Tras Afast. Esq.", larg_reguete, esp, h_area)
      pos_y_tr_esq = prof_movel - recuo_tras_afastador - esp
      reg_tr_esq.posicao_relativa = { pos_x: no_espacial.x, pos_y: pos_y_tr_esq, pos_z: no_espacial.z }
      reg_tr_esq.fita_borda = { direita: mat_frente }
      modulo.adicionar_peca(reg_tr_esq)
    end

    # --- CONSTRUÇÃO DO AFASTADOR DIREITO ---
    if afast_dir > 0
      x_dir = no_espacial.x + no_espacial.w - larg_reguete 

      # 1. Ripa Frontal
      reg_fr_dir = Peca.new(modulo.id_modulo, :afastador_interno, "Ripa Frontal Afast. Dir.", larg_reguete, esp, h_area)
      reg_fr_dir.posicao_relativa = { pos_x: x_dir, pos_y: recuo_front_afastador, pos_z: no_espacial.z }
      reg_fr_dir.fita_borda = { esquerda: mat_frente }
      modulo.adicionar_peca(reg_fr_dir)

      # 2. Suporte Central
      suporte_dir = Peca.new(modulo.id_modulo, :afastador_interno, "Suporte Corredica Dir.", esp, prof_central, h_area)
      suporte_dir.posicao_relativa = { pos_x: x_dir, pos_y: recuo_front_afastador + esp, pos_z: no_espacial.z }
      suporte_dir.fita_borda = {}
      modulo.adicionar_peca(suporte_dir)

      # 3. Ripa Traseira
      reg_tr_dir = Peca.new(modulo.id_modulo, :afastador_interno, "Ripa Tras Afast. Dir.", larg_reguete, esp, h_area)
      pos_y_tr_dir = prof_movel - recuo_tras_afastador - esp
      reg_tr_dir.posicao_relativa = { pos_x: x_dir, pos_y: pos_y_tr_dir, pos_z: no_espacial.z }
      reg_tr_dir.fita_borda = { esquerda: mat_frente }
      modulo.adicionar_peca(reg_tr_dir)
    end

    # ========================================================================
    # 🚀 5. DISTRIBUIÇÃO MATEMÁTICA DE ALTURAS E GAPS
    # ========================================================================
    h_util_frentes = h_area - gap_inf_base_especial

    h_frente = (h_util_frentes - (gap_int * (qtd_gavetas - 1))) / qtd_gavetas.to_f
    h_frente_final = h_frente - gap_mao_superior

    w_caixote_tecnico = w_vao_util 
    x_caixote_pos     = x_interno_vao

    gap_escape_frente = modulo.parametros_globais[:gap_esc] || 4.0 
    w_frente_util = w_caixote_tecnico - (gap_escape_frente * 2)
    x_frente_pos  = x_caixote_pos + gap_escape_frente

    z_acumulado = no_espacial.z + gap_inf_base_especial

    qtd_gavetas.times do |i|
      id_vinculo = SecureRandom.uuid

      categoria_f = config_no["tipo_deslizante"] == "sapateira_deslizante" ? :frente_sapateira : :frente_gaveta_interna
      nome_f = (config_no["tipo_deslizante"] == "sapateira_deslizante" ? "Sapateira Int." : "Gaveta Int.") + " #{i+1}"

      # Criação da Frente com folga visual anti-atrito
      frente = Peca.new(modulo.id_modulo, categoria_f, nome_f, w_frente_util, esp, h_frente_final)
      
      # Atribuição dinâmica do material de frentes e fitas de borda
      frente.definir_material!(mat_frente)
      frente.fita_borda = { frontal: mat_frente, esquerda: mat_frente, direita: mat_frente, superior: mat_frente, inferior: mat_frente }
      
      frente.id_vinculo_structure = id_vinculo
      frente.posicao_relativa = { pos_x: x_frente_pos, pos_y: recuo_front_afastador, pos_z: z_acumulado }
      modulo.adicionar_peca(frente)

      # Fabricação do Caixote Interno da Gaveta
      if defined?(ConstrutorGavetas)
        alt_caixote_util = h_frente_final - reducao_caixote_corpo
        ConstrutorGavetas.fabricar_caixote(modulo, id_vinculo, w_caixote_tecnico, alt_caixote_util, prof_livre_interna, z_acumulado, x_caixote_pos, { recuo_frente: recuo_front_afastador + esp })
      end

      z_acumulado += (h_frente + gap_int)
    end
  end

end