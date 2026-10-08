# ==============================================================================
# MENU DO SKETCHUP: CONTROLADOR DE CONTEXTO (Sketchup/Menu.rb)
# ==============================================================================

unless file_loaded?("TiranoGio_Menu")
  # 1. O Menu Tradicional na barra superior (Plugins > TiranoGio CAD)
  menu = UI.menu('Plugins').add_submenu('TiranoGio CAD')
  
  menu.add_item('Abrir Construtor Paramétrico') {
    ::ControladorPainel.abrir
  }

  # 2. O MENU DE CONTEXTO DINÂMICO (Botão Direito do Mouse)
  UI.add_context_menu_handler do |context_menu|
    modelo = Sketchup.active_model
    selecao = modelo.selection
    
    # Exibe as ferramentas se houver exatamente um Grupo selecionado com a assinatura do plugin
    if selecao.length == 1 && selecao.first.is_a?(Sketchup::Group)
      grupo = selecao.first
      
      if grupo.get_attribute("TiranoGio", "is_modulo")
        context_menu.add_item("⚙️ Editar Módulo (TiranoGio)") {
          ::ControladorPainel.abrir(grupo)
        }
      end
    end
  end

  file_loaded("TiranoGio_Menu")
end