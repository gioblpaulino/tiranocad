# ==============================================================================
# CONSTRUTOR DE INTERNOS: PORTA TEMPERO ISOLADO V2 (Regras/ConstrutorPortaTempero.rb)
# ==============================================================================

class ConstrutorPortaTempero
 
  TRILHO_MINIMO = 250.0
  TRILHO_MAXIMO = 500.0
  DESCONTO_TRILHO = 50.0
  FOLGA_CORREDICA_LATERAL = 13.0

  def self.fabricar(modulo, id_vinculo_tempero, w_livre, h_livre, prof_livre, z_frente, x_vao)
    perfil = GerenciadorPerfis.obter_perfil(modulo.parametros_globais[:perfil_montagem] || "Padrao_Gemini")
    nom = perfil[:nomenclatura] || {}
    esp = modulo.parametros_globais[:espessura_mdf] 

    prof_maxima = prof_livre - DESCONTO_TRILHO 
    tamanho_trilho = (prof_maxima / 50.0).floor * 50.0
 
    tamanho_trilho = TRILHO_MAXIMO if tamanho_trilho > TRILHO_MAXIMO
    tamanho_trilho = TRILHO_MINIMO if tamanho_trilho < TRILHO_MINIMO
    prof_caixote = tamanho_trilho

    w_caixote = w_livre - (FOLGA_CORREDICA_LATERAL * 2)
    h_caixote = h_livre - 30.0 
 
    x_inicial = x_vao + FOLGA_CORREDICA_LATERAL 
    y_inicial = 0.0 
    z_inicial = z_frente + 15.0 

    # Dicionário comercial amigável
    lbl_base = nom[:base_porta_tempero] || "Base Porta Tempero"
    lbl_fnd = nom[:traseira_porta_tempero] || "Traseira Porta Tempero"
    lbl_cf = nom[:contra_frente_tempero] || "Contra-Frente Tempero"
    lbl_prat = nom[:prateleira_tempero] || "Prateleira Interna Tempero"
    lbl_haste = nom[:haste_lateral_tempero] || "Haste Protetora"

    # Base Estrutural
    base = Peca.new(modulo.id_modulo, :base_porta_tempero, lbl_base, w_caixote, prof_caixote - (esp * 2), esp)
    base.id_vinculo_structure = id_vinculo_tempero
    base.posicao_relativa = { pos_x: x_inicial, pos_y: y_inicial + esp, pos_z: z_inicial }
    modulo.adicionar_peca(base)

    # Painéis Verticais
    h_verticais = h_caixote - esp
 
    fundo = Peca.new(modulo.id_modulo, :traseira_porta_tempero, lbl_fnd, w_caixote, esp, h_verticais)
    fundo.id_vinculo_structure = id_vinculo_tempero
    fundo.posicao_relativa = { pos_x: x_inicial, pos_y: y_inicial + prof_caixote - esp, pos_z: z_inicial }
    modulo.adicionar_peca(fundo)
 
    contra_frente = Peca.new(modulo.id_modulo, :contra_frente_tempero, lbl_cf, w_caixote, esp, h_verticais)
    contra_frente.id_vinculo_structure = id_vinculo_tempero
    contra_frente.posicao_relativa = { pos_x: x_inicial, pos_y: y_inicial, pos_z: z_inicial }
    modulo.adicionar_peca(contra_frente)

    # Prateleira Divisória Intermediária
    z_meio = z_inicial + (h_verticais / 2.0)
    prat = Peca.new(modulo.id_modulo, :prateleira_interno_tempero, lbl_prat, w_caixote, prof_caixote - (esp * 2), esp)
    prat.id_vinculo_structure = id_vinculo_tempero
    prat.posicao_relativa = { pos_x: x_inicial, pos_y: y_inicial + esp, pos_z: z_meio }
    modulo.adicionar_peca(prat)

    # Hastes de Proteção Anti-Queda
    h_haste = 70.0
    y_haste = y_inicial + esp
    d_haste = prof_caixote - (esp * 2)
    x_haste_dir = x_inicial + w_caixote - esp
 
    # Guarda-corpos inferior
    z_haste_inf = z_inicial + esp + 15.0
    haste_inf_esq = Peca.new(modulo.id_modulo, :haste_protecao_inf_esq, "#{lbl_haste} Inf. Esq.", esp, d_haste, h_haste)
    haste_inf_esq.id_vinculo_structure = id_vinculo_tempero
    haste_inf_esq.posicao_relativa = { pos_x: x_inicial, pos_y: y_haste, pos_z: z_haste_inf }
    modulo.adicionar_peca(haste_inf_esq)

    haste_inf_dir = Peca.new(modulo.id_modulo, :haste_protecao_inf_dir, "#{lbl_haste} Inf. Dir.", esp, d_haste, h_haste)
    haste_inf_dir.id_vinculo_structure = id_vinculo_tempero
    haste_inf_dir.posicao_relativa = { pos_x: x_haste_dir, pos_y: y_haste, pos_z: z_haste_inf }
    modulo.adicionar_peca(haste_inf_dir)
 
    # Guarda-corpos superior
    z_haste_sup = z_meio + esp + 15.0
    haste_sup_esq = Peca.new(modulo.id_modulo, :haste_protecao_sup_esq, "#{lbl_haste} Sup. Esq.", esp, d_haste, h_haste)
    haste_sup_esq.id_vinculo_structure = id_vinculo_tempero
    haste_sup_esq.posicao_relativa = { pos_x: x_inicial, pos_y: y_haste, pos_z: z_haste_sup }
    modulo.adicionar_peca(haste_sup_esq)

    haste_sup_dir = Peca.new(modulo.id_modulo, :haste_protecao_sup_dir, "#{lbl_haste} Sup. Dir.", esp, d_haste, h_haste)
    haste_sup_dir.id_vinculo_structure = id_vinculo_tempero
    haste_sup_dir.posicao_relativa = { pos_x: x_haste_dir, pos_y: y_haste, pos_z: z_haste_sup }
    modulo.adicionar_peca(haste_sup_dir)
  end
end