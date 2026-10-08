# ==============================================================================
# MOTOR DE DADOS: GERENCIADOR DE PERFIS DA MARCENARIA (Regras/GerenciadorPerfis.rb)
# ==============================================================================
require 'json'

class GerenciadorPerfis

  DEFAULTS_RESTRICOES = {
    comprimento_max_mdf: 2750.0,
    largura_max_mdf: 1830.0,
    refilo_seguranca: 30.0,
    largura_max_vao_livre: 900.0
  }.freeze

  DEFAULTS_NOMENCLATURA = {
    lateral_esquerda: "Lateral Esquerda",
    lateral_direita: "Lateral Direita",
    base_inferior: "Base Inferior",
    base_superior: "Base Superior / Teto",
    fundo_costa: "Fundo Costa",
    sarrafo_frontal: "Sarrafo Frontal",
    sarrafo_traseiro_em_pe: "Sarrafo Traseiro em Pé",
    sarrafo_traseiro_deitado: "Sarrafo Traseiro Deitado",
    batente_cava: "Batente Cava",
    reforco_cava: "Reforço Cava",
    divisoria_vertical: "Divisória Vertical",
    prateleira_fixa: "Prateleira Fixa",
    prateleira_livre: "Prateleira Livre",
    porta_giro_esquerda: "Porta Esquerda",
    porta_giro_direita: "Porta Direita",
    frente_gaveta: "Frente Gaveta",
    frente_gavetaao: "Frente Gavetão",
    lateral_gaveta: "Lateral de Gaveta",
    ctrf_gaveta: "Contra-Frente Gaveta",
    traseira_gaveta: "Traseira Gaveta",
    fundo_gaveta: "Fundo Gaveta",
    frente_porta_tempero: "Frente Porta Tempero",
    base_porta_tempero: "Base Porta Tempero",
    traseira_porta_tempero: "Traseira Porta Tempero",
    contra_frente_tempero: "Contra-Frente Tempero",
    prateleira_interno_tempero: "Prateleira Interna Tempero"
  }.freeze

   PERFIL_BASE = {
    espessura_mdf: 15.0,
    espessura_fundo: 6.0,
    recuo_fundo: 15.0,
    recuo_fundo_gav: 15.0,
    gap_sup: 4.0, gap_inf: 4.0, gap_lat: 4.0, gap_int: 4.0, gap_esc: 4.0,
    recuo_frt_prat: 20.0, recuo_trs_prat: 22.0,
    recuo_frt_div: 0.0, recuo_trs_div: 22.0,
    tipo_montagem_caixa: "Minifix",
    cava_ativa: false,

    nomenclatura: DEFAULTS_NOMENCLATURA,
    restricoes_chapa: DEFAULTS_RESTRICOES,

    geometria: {
      largura_sarrafo: 70.0,
      altura_cava: 35.0,
      prof_rasgo_fundo: 6.0,
      largura_regua_afastador: 60.0
    },

    # 🚀 EXPANSÃO PARA SUPORTE COMPLETO A GAVETAS (Sem Magic Numbers)
    gaveta: {
      folga_altura_caixote: 30.0,
      recuo_trilho_frontal: 37.0,
      elevacao_caixote_z: 15.0,       # Elevação inferior do caixote (+15mm)
      offset_eixo_corredica_z: 45.0   # Offset do centro do trilho (+45mm)
    },

    # 🚀 EXPANSÃO PARA USINAGENS E FURACÕES (Sem Magic Numbers)
    usinagem: {
      gerar_furo_topo_parafuso: true,
      broca_cavilha: 6.0, broca_marcacoes: 3.0, broca_parafusos: 4.5,
      broca_pino_minifix: 5.0, broca_canecos: 35.0,
      prof_tambor_minifix: 13.0, prof_caneco: 11.5, prof_marcacao: 2.0,
      z_dobradica_inf: 100.0,
      recuo_furo_padrao: 32.0,
      folga_passante_parafuso: 3.0,    # Folga adicional do furo passante soberbo (+3mm)
      recuo_borda_dobradica: 100.0    # Recuo do topo/base para primeira dobradiça (100mm)
    },

    # 🚀 TABELA DECLARATIVA PARA QUANTIDADE DE DOBRADIÇAS
    regras_dobradicas: [
      { altura_max: 900.0, qtd: 2 },
      { altura_max: 1500.0, qtd: 3 },
      { altura_max: 2000.0, qtd: 4 },
      { altura_max: 99999.0, qtd: 5 }
    ]
  }.freeze

   PERFIL_BASE_18 = {
    espessura_mdf: 18.0,
    espessura_fundo: 6.0,
    recuo_fundo: 15.0,
    recuo_fundo_gav: 15.0,
    gap_sup: 4.0, gap_inf: 4.0, gap_lat: 4.0, gap_int: 4.0, gap_esc: 4.0,
    recuo_frt_prat: 20.0, recuo_trs_prat: 22.0,
    recuo_frt_div: 0.0, recuo_trs_div: 22.0,
    tipo_montagem_caixa: "Minifix",
    cava_ativa: false,
    
    nomenclatura: DEFAULTS_NOMENCLATURA,
    restricoes_chapa: DEFAULTS_RESTRICOES,
  
    geometria: {
      largura_sarrafo: 70.0,
      altura_cava: 35.0,
      prof_rasgo_fundo: 6.0,
      largura_regua_afastador: 60.0
    },
    
    # 🚀 EXPANSÃO PARA SUPORTE COMPLETO A GAVETAS (Sem Magic Numbers)
    gaveta: {
      folga_altura_caixote: 30.0,
      recuo_trilho_frontal: 37.0,
      elevacao_caixote_z: 15.0,       # Elevação inferior do caixote (+15mm)
      offset_eixo_corredica_z: 45.0   # Offset do centro do trilho (+45mm)
    },
    
    # 🚀 EXPANSÃO PARA USINAGENS E FURACÕES (Sem Magic Numbers)
    usinagem: {
      gerar_furo_topo_parafuso: true,
      broca_cavilha: 6.0, broca_marcacoes: 3.0, broca_parafusos: 4.5,
      broca_pino_minifix: 5.0, broca_canecos: 35.0,
      prof_tambor_minifix: 13.0, prof_caneco: 11.5, prof_marcacao: 2.0,
      z_dobradica_inf: 100.0,
      recuo_furo_padrao: 32.0,
      folga_passante_parafuso: 3.0,    # Folga adicional do furo passante soberbo (+3mm)
      recuo_borda_dobradica: 100.0    # Recuo do topo/base para primeira dobradiça (100mm)
    },
  
    # 🚀 TABELA DECLARATIVA PARA QUANTIDADE DE DOBRADIÇAS
    regras_dobradicas: [
      { altura_max: 900.0, qtd: 2 },
      { altura_max: 1500.0, qtd: 3 },
      { altura_max: 2000.0, qtd: 4 },
      { altura_max: 99999.0, qtd: 5 }
    ]
  }.freeze

  PERFIL_BASE_25 = {
    espessura_mdf: 25.0,
    espessura_fundo: 6.0,
    recuo_fundo: 15.0,
    recuo_fundo_gav: 15.0,
    gap_sup: 4.0, gap_inf: 4.0, gap_lat: 4.0, gap_int: 4.0, gap_esc: 4.0,
    recuo_frt_prat: 20.0, recuo_trs_prat: 22.0,
    recuo_frt_div: 0.0, recuo_trs_div: 22.0,
    tipo_montagem_caixa: "Minifix",
    cava_ativa: false,
    
    nomenclatura: DEFAULTS_NOMENCLATURA,
    restricoes_chapa: DEFAULTS_RESTRICOES,
  
    geometria: {
      largura_sarrafo: 70.0,
      altura_cava: 35.0,
      prof_rasgo_fundo: 6.0,
      largura_regua_afastador: 60.0
    },
    
    # 🚀 EXPANSÃO PARA SUPORTE COMPLETO A GAVETAS (Sem Magic Numbers)
    gaveta: {
      folga_altura_caixote: 30.0,
      recuo_trilho_frontal: 37.0,
      elevacao_caixote_z: 15.0,       # Elevação inferior do caixote (+15mm)
      offset_eixo_corredica_z: 45.0   # Offset do centro do trilho (+45mm)
    },
    
    # 🚀 EXPANSÃO PARA USINAGENS E FURACÕES (Sem Magic Numbers)
    usinagem: {
      gerar_furo_topo_parafuso: true,
      broca_cavilha: 6.0, broca_marcacoes: 3.0, broca_parafusos: 4.5,
      broca_pino_minifix: 5.0, broca_canecos: 35.0,
      prof_tambor_minifix: 13.0, prof_caneco: 11.5, prof_marcacao: 2.0,
      z_dobradica_inf: 100.0,
      recuo_furo_padrao: 32.0,
      folga_passante_parafuso: 3.0,    # Folga adicional do furo passante soberbo (+3mm)
      recuo_borda_dobradica: 100.0    # Recuo do topo/base para primeira dobradiça (100mm)
    },
  
    # 🚀 TABELA DECLARATIVA PARA QUANTIDADE DE DOBRADIÇAS
    regras_dobradicas: [
      { altura_max: 900.0, qtd: 2 },
      { altura_max: 1500.0, qtd: 3 },
      { altura_max: 2000.0, qtd: 4 },
      { altura_max: 99999.0, qtd: 5 }
    ]
  }.freeze

  @@perfis = {
    "Padrao_Gemini"           => PERFIL_BASE,
    "Padrao_Gemini_Cava"      => PERFIL_BASE.merge(cava_ativa: true),
    "Padrao_Convencional_15mm"     => PERFIL_BASE.merge(tipo_montagem_caixa: "Parafuso_Soberbo", gap_esc: 4.0),
    "Padrao_Convencional_18mm" => PERFIL_BASE_18.merge(tipo_montagem_caixa: "Parafuso_Soberbo", gap_esc: 4.0),
    "Padrao_Convencional_25mm" => PERFIL_BASE_25.merge(tipo_montagem_caixa: "Parafuso_Soberbo", gap_esc: 4.0),
    "Padrao_Convencional_Cava" => PERFIL_BASE.merge(tipo_montagem_caixa: "Parafuso_Soberbo", cava_ativa: true, gap_esc: 4.0)

  }

  def self.obter_perfil(nome_perfil)
    @@perfis[nome_perfil] || @@perfis["Padrao_Gemini"]
  end

end