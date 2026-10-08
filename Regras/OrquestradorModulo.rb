# ==============================================================================
# ORQUESTRADOR DE MONTAGEM: DIRETOR DE FLUXO MULTI-FAMÍLIA (OrquestradorModulo.rb)
# ==============================================================================
require 'net/http'
require 'uri'
require 'json'
require_relative 'GerenciadorPerfis'
require_relative 'ConstrutorInferior'
require_relative 'ConstrutorAereo'
require_relative 'ConstrutorAlto'
require_relative 'ConstrutorInternos'
require_relative 'ConstrutorFrentes'

class OrquestradorModulo

  def self.fabricar_inferior(params)
    # 1. RESOLUÇÃO DE PERFIL ATIVO E DUPLICAÇÃO DE SEGURANÇA
    nome_perfil = params["perfil_montagem"] || "Padrao_Gemini"
    perfil_original = GerenciadorPerfis.obter_perfil(nome_perfil)
    
    # Cria uma cópia isolada na memória para evitar contaminação do banco global
    perfil_ativo = perfil_original ? perfil_original.dup : GerenciadorPerfis.obter_perfil("Padrao_Gemini").dup

    perfil_ativo[:geometria] = perfil_ativo[:geometria] ? perfil_ativo[:geometria].dup : {}
    perfil_ativo[:usinagem]  = perfil_ativo[:usinagem]  ? perfil_ativo[:usinagem].dup  : {}


     # 🚀 SOBREESCRITA DINÂMICA DOS AJUSTES DE FÁBRICA
    if params["param_prof_rasgo"] || params["param_furo_front"]
      # Geometria e Canais
      perfil_ativo[:geometria][:prof_rasgo_fundo]   = params["param_prof_rasgo"].to_f  if params["param_prof_rasgo"]
      perfil_ativo[:geometria][:largura_canal_fundo] = params["param_larg_rasgo"].to_f  if params["param_larg_rasgo"]
    
      # Brocas
      perfil_ativo[:usinagem][:broca_pino_minifix] = params["param_broca_minifix"].to_f  if params["param_broca_minifix"]
      perfil_ativo[:usinagem][:broca_parafusos]   = params["param_broca_parafuso"].to_f if params["param_broca_parafuso"]
      perfil_ativo[:usinagem][:broca_cavilha]    = params["param_broca_cavilha"].to_f  if params["param_broca_cavilha"]
      perfil_ativo[:usinagem][:broca_canecos]    = params["param_broca_caneco"].to_f   if params["param_broca_caneco"]
    
      # 🚀 REGISTRO DIRETO NO PERFIL ATIVO (1º Furo, Último Furo e Vão Máximo)
      perfil_ativo[:usinagem][:recuo_furo_frontal] = (params["param_furo_front"] || 50.0).to_f
      perfil_ativo[:usinagem][:recuo_furo_traseiro] = (params["param_furo_tras"] || 50.0).to_f
      perfil_ativo[:usinagem][:vao_maximo_furos]    = (params["param_furo_max_vao"] || 250.0).to_f
      perfil_ativo[:usinagem][:recuo_furo_gaveta]   = (params["param_furo_gaveta"] || 30.0).to_f
    end

    opcoes_caixa[:perfil_objeto_custom] = perfil_ativo if defined?(opcoes_caixa) && opcoes_caixa


    # 🚀 CORREÇÃO DO RECUO DINÂMICO DO FUNDO (Sincronização com a Interface)
    recuo_fundo_dinamico = params["param_recuo_fundo"] ? params["param_recuo_fundo"].to_f : perfil_ativo[:recuo_fundo]
    perfil_ativo[:recuo_fundo] = recuo_fundo_dinamico
    
    usa_cava = perfil_ativo[:cava_ativa] || false

    # Coerção de segurança das dimensões
    w = params["w"].to_f
    h = params["h"].to_f
    d = params["d"].to_f

    mat_caixa = params["material_caixaria"] || "generico_branco_tx"
    mat_frente = params["material_frentes"] || "arauco_louro_freijo"

    fitas_opcoes = {
      frontal: params["fita_borda_frontal"] ? mat_caixa : nil,
      traseira: params["fita_borda_traseira"] ? mat_caixa : nil,
      esquerda: params["fita_borda_esquerda"] ? mat_caixa : nil,
      direita: params["fita_borda_direita"] ? mat_caixa : nil
    }

    # 2. SELEÇÃO DINÂMICA DE FABRICAÇÃO BASEADO NA CATEGORIA
    categoria = params["categoria_modulo"] || "INFERIOR"

    case categoria
    when "AEREO"
      opcoes_aereo = {
        montagem: params["montagem_caixa"],
        fundo_recuado: recuo_fundo_dinamico,
        fixacao: params["tipo_sarrafo_tras"],
        nome_perfil_ativo: nome_perfil,
        perfil_objeto_custom: perfil_ativo,
        material_caixaria: mat_caixa,
        material_frentes: mat_frente,
        fitas_custom: fitas_opcoes
      }
      modulo = ::ConstrutorAereo.fabricar("Aereo_Personalizado", w, h, d, opcoes_aereo)

    when "TORRE_ALTA", "ROUPEIRO"
      opcoes_altos = {
        montagem: params["montagem_caixa"],
        fundo_recuado: recuo_fundo_dinamico,
        fixacao: "Duplo_Reforco", 
        familia_especifica: categoria == "ROUPEIRO" ? "MODULO_ROUPEIRO" : "MODULO_TORRE",
        nome_perfil_ativo: nome_perfil,
        perfil_objeto_custom: perfil_ativo,
        material_caixaria: mat_caixa,
        material_frentes: mat_frente, 
        fitas_custom: fitas_opcoes
      }
      modulo = ::ConstrutorAlto.fabricar("Coluna_Alta_Personalizada", w, h, d, opcoes_altos)

    else # INFERIOR / BALCÃO
      opcoes_caixa = {
        montagem: params["montagem_caixa"],
        fita_laterais_base: params["fita_laterais_base"],
        fundo: params["com_fundo"],
        recuo_fundo_custom: recuo_fundo_dinamico, # Injeção assegurada para o Construtor
        tipo_sarrafo_tras: params["tipo_sarrafo_tras"],
        cava: usa_cava,
        nome_perfil_ativo: nome_perfil,
        perfil_objeto_custom: perfil_ativo, # 🚀 CORREÇÃO: Passa o objeto do perfil já sobrescrito
        material_caixaria: mat_caixa,
        material_frentes: mat_frente,
        fitas_custom: fitas_opcoes
      }
      modulo = ::ConstrutorInferior.fabricar("Balcao_Personalizado", w, h, d, opcoes_caixa)
    end

    modulo.id_modulo = params["id_edicao"] if params["id_edicao"] && params["id_edicao"] != ""

    modulo.parametros_globais[:perfil_ativo] = perfil_ativo
    modulo.parametros_globais[:perfil_montagem] = nome_perfil

    # Vincula o DNA dinâmico atualizado no dicionário global do Módulo recém-nascido
    modulo.parametros_globais[:prof_rasgo_dinamico] = perfil_ativo[:geometria][:prof_rasgo_fundo]
    modulo.parametros_globais[:largura_canal_dinamico] = perfil_ativo[:geometria][:largura_canal_fundo]
    modulo.parametros_globais[:recuo_fundo] = perfil_ativo[:recuo_fundo]

    # 3. INJEÇÃO DOS GAPS DE DESIGN NAS FRENTES
    modulo.parametros_globais[:gap_sup] = (params["gap_sup"] || 4.0).to_f
    modulo.parametros_globais[:gap_inf] = (params["gap_inf"] || 4.0).to_f
    modulo.parametros_globais[:gap_lat] = (params["gap_lat"] || 4.0).to_f
    modulo.parametros_globais[:gap_int] = (params["gap_int"] || 4.0).to_f

    modulo.parametros_globais[:recuo_frt_prat] = (params["param_recuo_frt_prat"] || 20.0).to_f
    modulo.parametros_globais[:recuo_trs_prat] = (params["param_recuo_trs_prat"] || 22.0).to_f
    modulo.parametros_globais[:recuo_frt_div] = (params["param_recuo_frt_div"] || 0.0).to_f
    modulo.parametros_globais[:recuo_trs_div] = (params["param_recuo_trs_div"] || 22.0).to_f

    modulo.parametros_globais[:dist_furo_front]     = perfil_ativo[:usinagem][:recuo_furo_frontal]
    modulo.parametros_globais[:dist_furo_tras]      = perfil_ativo[:usinagem][:recuo_furo_traseiro]
    modulo.parametros_globais[:dist_furo_max_vao]  = perfil_ativo[:usinagem][:vao_maximo_furos]
    modulo.parametros_globais[:dist_furo_gaveta]   = perfil_ativo[:usinagem][:recuo_furo_gaveta]

    modulo.parametros_globais[:broca_canecos]       = perfil_ativo[:usinagem][:broca_canecos]
    modulo.parametros_globais[:broca_parafusos]     = perfil_ativo[:usinagem][:broca_parafusos]
    modulo.parametros_globais[:broca_pino_minifix]  = perfil_ativo[:usinagem][:broca_pino_minifix]
    modulo.parametros_globais[:broca_cavilha]       = perfil_ativo[:usinagem][:broca_cavilha]

    # Injeção do DNA estrutural do Perfil para os construtores internos
    modulo.parametros_globais[:espessura_mdf]   = perfil_ativo[:espessura_mdf]
    modulo.parametros_globais[:espessura_fundo] = perfil_ativo[:espessura_fundo]
    modulo.parametros_globais[:recuo_frt_prat]  ||= perfil_ativo[:recuo_frt_prat] || perfil_ativo[:recuo_prat_front]
    modulo.parametros_globais[:recuo_trs_prat]  ||= perfil_ativo[:recuo_trs_prat] || perfil_ativo[:recuo_prat_tras]

    modulo.parametros_globais[:material_caixaria] = perfil_ativo[:material_caixaria] || params["material_caixaria"] || "generico_branco_tx"
    modulo.parametros_globais[:material_frentes]  = perfil_ativo[:material_frentes]  || params["material_frentes"]  || "arauco_louro_freijo"

    # ========================================================================
    # 🚀 MAPEAMENTO DA ÁRVORE BSP INTERNA (Suporte a Nós Pais e Folhas)
    # ========================================================================
    if params["arvore_json"] && params["arvore_json"] != ""
      begin
        arvore_raiz = ConstrutorInternos.gerar_arvore_e_pecas(modulo, params["arvore_json"])

        # Função recursiva simples para aplicar frentes sem bloquear os nós filhos
        processar_frentes_no = lambda do |no|
          return unless no

          config = no.conteudo
          if config && config["frente"] && config["frente"] != "nenhuma"
            aplicar_frente_bsp(modulo, no, config["frente"], config["qtd_frente"])
          end

          # Continua descendo na árvore para processar também os nós filhos
          processar_frentes_no.call(no.filho_a) if no.filho_a
          processar_frentes_no.call(no.filho_b) if no.filho_b
        end

        # Inicia a busca a partir da raiz da árvore
        processar_frentes_no.call(arvore_raiz)

      rescue StandardError => e
        puts "⚠️ Falha crítica ao processar árvore interna BSP: #{e.message}"
      end
    end

    return modulo
  end

  def self.enviar_para_flask(modulo_obj)
    # Transforma o módulo real calculando usinagens e caixaria em Hash puro
    payload_hash = modulo_obj.para_hash
    payload_json = JSON.generate(payload_hash)

    uri = URI.parse("http://localhost:5000/api/modulo")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
    request.body = payload_json

    begin
      puts "📡 Despachando módulo real #{modulo_obj.id_modulo} para o Flask..."
      resposta = http.request(request)
      if resposta.code == "200"
        puts "🎉 Sincronização Web concluída com sucesso absoluta!"
      else
        puts "⚠️ Servidor Flask rejeitou o payload. Código: #{resposta.code}"
      end
    rescue StandardError => e
      puts "❌ Falha ao conectar com o servidor Flask (app.py rodando?): #{e.message}"
    end
  end
  
  def self.aplicar_frente_bsp(modulo, no_espacial, tipo, qtd)
    qtd_frentes = qtd.to_i
    case tipo
    when "portas"
      ConstrutorFrentes.adicionar_portas_giro(modulo, no_espacial, qtd_frentes)
    when "gavetas"
      # Passagem completa dos parâmetros de folgas industriais
      ConstrutorFrentes.adicionar_gaveteiro(modulo, no_espacial, qtd_frentes, { desconto_50mm: true, rebaixo_cf_tras: 5.0 })
    when "gavetas_internas"
      ConstrutorFrentes.adicionar_gaveteiro_interno(modulo, no_espacial, qtd.to_i)
    when "sapateiras_internas"
     no_espacial.conteudo["tipo_deslizante"] = "sapateira_deslizante"
    ConstrutorFrentes.adicionar_sapateira_deslizante(modulo, no_espacial, qtd_frentes)
    when "porta_tempero"
      # Reparação de escopo para construtor interno de tempero em L/U
      if ConstrutorFrentes.respond_to?(:adicionar_porta_tempero)
        # Se implementado dinamicamente no construtor de frentes
        ConstrutorFrentes.adicionar_porta_tempero(modulo, no_espacial)
      else
        # Fallback direto caso o motor geométrico chame a classe especializada de internos
        w_l = no_espacial.w; h_l = no_espacial.h; p_l = no_espacial.d - 35.0
        ::ConstrutorPortaTempero.fabricar(modulo, "TEMP_#{no_espacial.id}", w_l, h_l, p_l, no_espacial.z, no_espacial.x)
      end
    else
      puts "Aviso: Componente frontal do tipo '#{tipo}' desconhecido."
    end
    return modulo
  end
end