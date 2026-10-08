# ==============================================================================
# MOTOR DE REGRAS: CONSTRUTOR DE INTERNOS BSP V2 (Regras/ConstrutorInternos.rb)
# ==============================================================================
require_relative 'NoEspacial'
require 'json'

class ConstrutorInternos

  def self.gerar_arvore_e_pecas(modulo, arvore_json_str)
    return nil if arvore_json_str.nil? || arvore_json_str.empty?

    esp = modulo.parametros_globais[:espessura_mdf]
    w = modulo.dimensoes_totais[:largura_x]
    h = modulo.dimensoes_totais[:altura_y]
    d = modulo.dimensoes_totais[:profundidade_z]

    # Origem do espaço interno descontando as espessuras das laterais e bases externas
    raiz_ruby = NoEspacial.new("V", esp, 0.0, esp, w - (esp * 2), h - (esp * 2), d, esp)
    dados_js = JSON.parse(arvore_json_str)
    
    decodificar_arvore_json(raiz_ruby, dados_js)
    materializar_nos(modulo, raiz_ruby)

    return raiz_ruby
  end

  def self.decodificar_arvore_json(no_ruby, no_js)
    return unless no_ruby && no_js # Blindagem contra objetos nulos
    
    # 🚀 CORREÇÃO: Garante a persistência dos dados (frentes/acessórios) no nó atual, seja pai ou folha
    no_ruby.conteudo = no_js["dados"] || {}
    
    ratio = no_js["splitRatio"] || 0.5
    
    if no_js["split"] == "v"
      largura_alvo = (no_ruby.w - no_ruby.espessura_mdf) * ratio
      sucesso = no_ruby.cortar_vertical(largura_alvo, no_js["filhoA"]["id"], no_js["filhoB"]["id"])
      
      if sucesso
        decodificar_arvore_json(no_ruby.filho_a, no_js["filhoA"])
        decodificar_arvore_json(no_ruby.filho_b, no_js["filhoB"])
      end
      
    elsif no_js["split"] == "h"
      altura_alvo = (no_ruby.h - no_ruby.espessura_mdf) * ratio
      # filhoA = Inferior (Base), filhoB = Superior (Teto)
      sucesso = no_ruby.cortar_horizontal(altura_alvo, no_js["filhoA"]["id"], no_js["filhoB"]["id"])
      
      if sucesso
        decodificar_arvore_json(no_ruby.filho_a, no_js["filhoA"])
        decodificar_arvore_json(no_ruby.filho_b, no_js["filhoB"])
      end
    end
  end

  def self.materializar_nos(modulo, no)
    return unless no

    # Resgatamos as configurações do perfil ativo da marcenaria
    perfil = GerenciadorPerfis.obter_perfil(modulo.parametros_globais[:perfil_montagem] || "Padrao_Gemini")
    nom = perfil[:nomenclatura] || {}

    # 🚀 CORREÇÃO DE CHAVES: Lê tanto com 'param_' quanto sem 'param_' para sincronizar 100% com a UI
    params = modulo.parametros_globais || {}

    r_prat_f = (params[:param_recuo_frt_prat] || params[:recuo_frt_prat] || 20.0).to_f
    r_prat_t = (params[:param_recuo_trs_prat]  || params[:recuo_trs_prat]  || 22.0).to_f
    r_div_f  = (params[:param_recuo_frt_div]  || params[:recuo_frt_div]  || 0.0).to_f
    r_div_t  = (params[:param_recuo_trs_div]   || params[:recuo_trs_div]   || 22.0).to_f

    # ========================================================================
    # 1. PRATELEIRAS MÓVEIS/LIVRES DENTRO DE UM VÃO FOLHA
    # ========================================================================
    if no.folha?
      config = no.conteudo
      if config && config["qtd_prat"] && config["qtd_prat"].to_i > 0
        qtd = config["qtd_prat"].to_i
        esp = no.espessura_mdf

        return if no.h <= (esp * qtd) + 30.0

        h_livre = (no.h - (esp * qtd)) / (qtd + 1).to_f
        d_prat = no.d - r_prat_f - r_prat_t

        qtd.times do |i|
          z_prat = no.z + h_livre + (i * (h_livre + esp))
          ferragem = config["ferragem_prat"] || "pino"

          categoria_p = "prateleira_livre_#{ferragem.downcase}".to_sym
          nome_comercial_p = (nom[:prateleira_livre] || "Prateleira Livre") + " #{i+1}"

          prat = Peca.new(modulo.id_modulo, categoria_p, nome_comercial_p, no.w, d_prat, esp)
          # Recuo frontal e traseiro aplicados corretamente na geometria
          prat.posicao_relativa = { pos_x: no.x, pos_y: no.y + r_prat_f, pos_z: z_prat }
          prat.fita_borda = { frontal: 1 }
          modulo.adicionar_peca(prat)
        end
      end
      return
    end

    # ========================================================================
    # 2. DIVISÕES ESTRUTURAIS (VERTICAIS E HORIZONTAIS) DA ÁRVORE BSP
    # ========================================================================
    cfg_corte = no.conteudo || {}

    if no.eixo_corte == :vertical
      # Divisórias Verticais: Acompanham r_div_f e r_div_t
      d_div = no.d - r_div_f - r_div_t
      nome_div = nom[:divisoria_vertical] || "Divisoria Vertical"
      esp_corte = no.espessura_mdf

      divisoria = Peca.new(modulo.id_modulo, :divisoria_vertical, nome_div, esp_corte, d_div, no.h)
      divisoria.posicao_relativa = { pos_x: no.filho_a.x + no.filho_a.w, pos_y: r_div_f, pos_z: no.z }
      divisoria.fita_borda = { frontal: 1 }
      modulo.adicionar_peca(divisoria)

    elsif no.eixo_corte == :horizontal
      # Divisões Horizontais
      tipo_divisao = cfg_corte["tipo_divisao"] || "prateleira_fixa"
      ferragem = cfg_corte["ferragem_prat"] || "pino"
      esp_corte = no.espessura_mdf

      if tipo_divisao == "prateleira_livre"
        # Prateleira Livre Móvel: Recua na frente (r_prat_f) e atrás (r_prat_t)
        d_prat = no.d - r_prat_f - r_prat_t
        nome_p = (nom[:prateleira_livre] || "Prateleira Livre")
        cat_p = "prateleira_livre_#{ferragem.downcase}".to_sym
        y_pos = r_prat_f
      else
        # Prateleira Fixa Estrutural: Rente à frente (r_div_f) e recua no fundo (r_div_t)
        d_prat = no.d - r_div_f - r_div_t
        nome_p = nom[:prateleira_fixa] || "Prateleira Fixa"
        cat_p = :prateleira_fixa
        y_pos = r_div_f
      end

      prateleira = Peca.new(modulo.id_modulo, cat_p, nome_p, no.w, d_prat, esp_corte)
      prateleira.posicao_relativa = { pos_x: no.x, pos_y: y_pos, pos_z: no.filho_a.z + no.filho_a.h }
      prateleira.fita_borda = { frontal: 1 }
      modulo.adicionar_peca(prateleira)
    end

    materializar_nos(modulo, no.filho_a) if no.filho_a
    materializar_nos(modulo, no.filho_b) if no.filho_b
  end
end