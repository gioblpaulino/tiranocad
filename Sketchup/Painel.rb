# ==============================================================================
# CONTROLADOR DA INTERFACE: API DE DIÁLOGO E CALLBACKS (Sketchup/Painel.rb)
# ==============================================================================

class ControladorPainel
  @@grupo_em_edicao = nil
  @dialog = nil # Variável de classe para controle de instância única

  def self.abrir(grupo_selecionado = nil)
    @@grupo_em_edicao = grupo_selecionado

    # Se a janela já existe e está aberta, traz ela para frente e atualiza os dados
    if @dialog && @dialog.visible?
      @dialog.bring_to_front
      self.atualizar_dados_edicao
      return
    end

    @dialog = UI::HtmlDialog.new({
      :dialog_title => @@grupo_em_edicao ? "Editando Módulo..." : "TiranoGio CAD - Fábrica",
      :width => 400, 
      :height => 700, 
      :style => UI::HtmlDialog::STYLE_DIALOG
    })

    caminho_html = File.join(__dir__, '..', 'UI', 'index.html')
    @dialog.set_file(caminho_html)

    @dialog.add_action_callback("paginaPronta") do |action_context|
      self.atualizar_dados_edicao
    end

    @dialog.add_action_callback("gerarBalcao") do |action_context, params|
      begin
        next puts "⚠️ Erro: Parâmetros de fabricação não recebidos." unless params.is_a?(Hash)
        
        # Sanitização de encoding para evitar conflitos no Windows
        params.each do |k, v|
          if v.is_a?(String)
            params[k] = v.force_encoding('UTF-8').encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
          end
        end
        
        id_edicao = params["id_edicao"]
        transformacao_antiga = nil
        
        if id_edicao && id_edicao != ""
          modelo = Sketchup.active_model
          grupo_velho = modelo.entities.find { |e| e.is_a?(Sketchup::Group) && e.get_attribute("TiranoGio", "id_original") == id_edicao }
          if grupo_velho && grupo_velho.valid?
            transformacao_antiga = grupo_velho.transformation 
            params["grupo_velho_instancia"] = grupo_velho
          end
        end
        
        # 1. Fabrica o DNA do módulo estrutural
        meu_modulo = ::OrquestradorModulo.fabricar_inferior(params)
        
        if params["grupo_velho_instancia"] && params["grupo_velho_instancia"].valid?
          params["grupo_velho_instancia"].erase!
        end
        
        # 2. Desenha a caixaria E calcula as usinagens CNC no modelo
        ::Renderizador.desenhar_modulo(meu_modulo, transformacao_antiga, params)
        
        # 🚀 SOLUÇÃO PONTO 2: Despacho centralizado pós-usinagem (Sem travamento)
        # Executado após o encerramento seguro da transação geométrica do SketchUp
        UI.start_timer(0.1, false) do
          ::OrquestradorModulo.enviar_para_flask(meu_modulo)
        end
        
      rescue StandardError => e
        UI.messagebox("Erro ao processar alteração paramétrica: #{e.message}")
      end
    end

    @dialog.add_action_callback("receberArvoreCopiloto") do |action_context, arvore_json_str|
      begin
        puts "🤖 Copiloto: Nova Árvore BSP recebida da IA!"
        
        unless @@grupo_em_edicao && @@grupo_em_edicao.valid?
          puts "⚠️ Nenhum módulo selecionado no SketchUp para reedição do Copiloto."
          next
        end
      
        id_edicao = @@grupo_em_edicao.get_attribute("TiranoGio", "id_original") || "001"
        w = @@grupo_em_edicao.get_attribute("TiranoGio", "w") || 800.0
        h = @@grupo_em_edicao.get_attribute("TiranoGio", "h") || 700.0
        d = @@grupo_em_edicao.get_attribute("TiranoGio", "d") || 550.0
      
        params = {
          "id_edicao" => id_edicao,
          "w" => w, "h" => h, "d" => d,
          "arvore_json" => arvore_json_str,
          "categoria_modulo" => @@grupo_em_edicao.get_attribute("TiranoGio", "categoria_modulo") || "INFERIOR",
          "perfil_montagem" => @@grupo_em_edicao.get_attribute("TiranoGio", "perfil_montagem") || "Padrao_Gemini",
          "material_caixaria" => @@grupo_em_edicao.get_attribute("TiranoGio", "material_caixaria") || "generico_branco_tx",
          "material_frentes" => @@grupo_em_edicao.get_attribute("TiranoGio", "material_frentes") || "arauco_louro_freijo",
          "montagem_caixa" => @@grupo_em_edicao.get_attribute("TiranoGio", "montagem_caixa") || "Base Passante",
          "tipo_sarrafo_tras" => @@grupo_em_edicao.get_attribute("TiranoGio", "tipo_sarrafo_tras") || "deitado",
          "com_fundo" => @@grupo_em_edicao.get_attribute("TiranoGio", "com_fundo"),
          "grupo_velho_instancia" => @@grupo_em_edicao
        }
      
        # Fabrica o novo DNA do módulo mantendo a posição tridimensional original
        meu_modulo = ::OrquestradorModulo.fabricar_inferior(params)
        
        transformacao_antiga = nil
        if params["grupo_velho_instancia"] && params["grupo_velho_instancia"].valid?
          transformacao_antiga = params["grupo_velho_instancia"].transformation
          params["grupo_velho_instancia"].erase!
        end
      
        # Renderiza a nova caixaria e usinagens
        ::Renderizador.desenhar_modulo(meu_modulo, transformacao_antiga, params)
        
        # Atualiza a referência global para o módulo reconstruído
        modelo = Sketchup.active_model
        @@grupo_em_edicao = modelo.entities.find { |e| e.is_a?(Sketchup::Group) && e.get_attribute("TiranoGio", "id_original") == id_edicao }
      
        # Re-sincroniza a janela HTML
        self.atualizar_dados_edicao
      
        puts "🎉 Copiloto: Módulo #{id_edicao} reconstruído com sucesso pelo Gemini!"
      rescue StandardError => e
        UI.messagebox("Erro ao aplicar alteração do Copiloto: #{e.message}")
      end
    end
    
    @dialog.add_action_callback("gerarAmbiente3D") do |action_context, params_amb|
      begin
        ::ConstrutorAmbiente.construir_comodo(params_amb)
      rescue StandardError => e
        UI.messagebox("Erro ao erguer paredes do quarto: #{e.message}")
      end
    end

    @dialog.show
  end

    def self.atualizar_dados_edicao
    if @dialog && @dialog.visible? && @@grupo_em_edicao && @@grupo_em_edicao.valid?
      id  = @@grupo_em_edicao.get_attribute("TiranoGio", "id_original") || "001"
      w   = @@grupo_em_edicao.get_attribute("TiranoGio", "w") || 800.0
      h   = @@grupo_em_edicao.get_attribute("TiranoGio", "h") || 700.0
      d   = @@grupo_em_edicao.get_attribute("TiranoGio", "d") || 550.0
      
      arvore_json     = @@grupo_em_edicao.get_attribute("TiranoGio", "arvore_json") || ""
      categoria       = @@grupo_em_edicao.get_attribute("TiranoGio", "categoria_modulo") || "INFERIOR"
      perfil          = @@grupo_em_edicao.get_attribute("TiranoGio", "perfil_montagem") || "Padrao_Gemini"
      mat_caixa       = @@grupo_em_edicao.get_attribute("TiranoGio", "material_caixaria") || "generico_branco_tx"
      mat_frentes     = @@grupo_em_edicao.get_attribute("TiranoGio", "material_frentes") || "arauco_louro_freijo"
      montagem_caixa  = @@grupo_em_edicao.get_attribute("TiranoGio", "montagem_caixa") || "Base Passante"
      sarrafo_tras    = @@grupo_em_edicao.get_attribute("TiranoGio", "tipo_sarrafo_tras") || "deitado"
      com_fundo       = @@grupo_em_edicao.get_attribute("TiranoGio", "com_fundo")
    
      dados_modulo = {
        id_edicao: id,
        w: w, h: h, d: d,
        arvore_json: arvore_json,
        categoria_modulo: categoria,
        perfil_montagem: perfil,
        material_caixaria: mat_caixa,
        material_frentes: mat_frentes,
        montagem_caixa: montagem_caixa,
        tipo_sarrafo_tras: sarrafo_tras,
        com_fundo: com_fundo
      }
    
      js_payload = dados_modulo.to_json
      js_comando = "preencherDadosEdicaoCompleto(#{js_payload});"
      
      # 🚀 TIMER DE SEGURANÇA: Garante o disparo após a renderização da janela
      UI.start_timer(0.15, false) do
        @dialog.execute_script(js_comando) if @dialog && @dialog.visible?
      end
    end
  end
  
end