# ==============================================================================
# MOTOR DE REGRAS: CONSTRUTOR DE GAVETAS PARAMÉTRICO V2 (Regras/ConstrutorGavetas.rb)
# ==============================================================================

class ConstrutorGavetas
 
  TRILHO_MINIMO = 250.0
  TRILHO_MAXIMO = 500.0
  DESCONTO_SEGURANCA_PADRAO = 50.0
 
  def self.fabricar_caixote(modulo_pai, id_vinculo_gaveta, w_vao, h_frente, prof_livre, pos_z_frente, x_interno_vao, opcoes={})
    perfil = GerenciadorPerfis.obter_perfil(modulo_pai.parametros_globais[:perfil_montagem] || "Padrao_Gemini")
    nom = perfil[:nomenclatura] || {}

    esp = modulo_pai.parametros_globais[:espessura_mdf]
    esp_fnd = modulo_pai.parametros_globais[:espessura_fundo]
    prof_rasgo = modulo_pai.parametros_globais[:prof_rasgo_dinamico] || 8.0
 
    recuo_corredica = opcoes.fetch(:recuo_corredica, 13.0) 
    rebaixo_cf_tras = opcoes.fetch(:rebaixo_cf_tras, 5.0)
    desconto_seguranca = opcoes.fetch(:desconto_50mm, true)

    prof_maxima = desconto_seguranca ? (prof_livre - DESCONTO_SEGURANCA_PADRAO) : prof_livre
    tamanho_trilho = (prof_maxima / 50.0).floor * 50.0

    tamanho_trilho = TRILHO_MAXIMO if tamanho_trilho > TRILHO_MAXIMO
    tamanho_trilho = TRILHO_MINIMO if tamanho_trilho < TRILHO_MINIMO
    d_gaveta = tamanho_trilho

    recuo_frente = opcoes.fetch(:recuo_frente, 0.0) 

    folga_caixote = perfil[:gaveta][:folga_altura_caixote] || 30.0
    alt_laterais = h_frente - folga_caixote
    alt_cf_tras = alt_laterais - rebaixo_cf_tras

    larg_caixote = w_vao - (recuo_corredica * 2)
    larg_interna_gaveta = larg_caixote - (esp * 2)

    x_inicial = x_interno_vao + recuo_corredica
    y_inicial = recuo_frente 
    z_inicial = pos_z_frente + 15.0

    # Materiais Comerciais Customizados pela Marcenaria
    lbl_lat_esq = (nom[:lateral_gaveta] || "Lateral Gaveta") + " Esq."
    lbl_lat_dir = (nom[:lateral_gaveta] || "Lateral Gaveta") + " Dir."
    lbl_cf = nom[:ctrf_gaveta] || "Contra-Frente"
    lbl_tras = nom[:traseira_gaveta] || "Traseira Gaveta"
    lbl_fnd = nom[:fundo_gaveta] || "Fundo Gaveta"

    mat_caixa = opcoes[:material_caixaria] || "generico_branco_tx"

    # Lateral Esquerda da Gaveta
    lat_esq_gav = Peca.new(modulo_pai.id_modulo, :lateral_gaveta_esquerda, lbl_lat_esq, esp, d_gaveta, alt_laterais)
    lat_esq_gav.id_vinculo_structure = id_vinculo_gaveta
    lat_esq_gav.posicao_relativa = { pos_x: x_inicial, pos_y: y_inicial, pos_z: z_inicial }
    lat_esq_gav.definir_material!(mat_caixa)
    lat_esq_gav.fita_borda = { superior: mat_caixa }
    modulo_pai.adicionar_peca(lat_esq_gav)
    
    # Lateral Direita da Gaveta
    lat_dir_gav = Peca.new(modulo_pai.id_modulo, :lateral_gaveta_direita, lbl_lat_dir, esp, d_gaveta, alt_laterais)
    lat_dir_gav.id_vinculo_structure = id_vinculo_gaveta
    lat_dir_gav.posicao_relativa = { pos_x: x_inicial + larg_caixote - esp, pos_y: y_inicial, pos_z: z_inicial }
    lat_dir_gav.definir_material!(mat_caixa)
    lat_dir_gav.fita_borda = { superior: mat_caixa }
    modulo_pai.adicionar_peca(lat_dir_gav)

    # Fechamentos Verticais (Contra-Frente e Traseira)
    contra_frente = Peca.new(modulo_pai.id_modulo, :ctrf_gaveta, lbl_cf, larg_interna_gaveta, esp, alt_cf_tras)
    contra_frente.id_vinculo_structure = id_vinculo_gaveta
    contra_frente.posicao_relativa = { pos_x: x_inicial + esp, pos_y: y_inicial, pos_z: z_inicial }
    contra_frente.definir_material!(mat_caixa)
    contra_frente.fita_borda = { superior: mat_caixa }
    modulo_pai.adicionar_peca(contra_frente)

    traseira = Peca.new(modulo_pai.id_modulo, :traseira_gaveta, lbl_tras, larg_interna_gaveta, esp, alt_cf_tras)
    traseira.id_vinculo_structure = id_vinculo_gaveta
    traseira.posicao_relativa = { pos_x: x_inicial + esp, pos_y: y_inicial + d_gaveta - esp, pos_z: z_inicial }
    traseira.definir_material!(mat_caixa)
    traseira.fita_borda = { superior: mat_caixa }
    modulo_pai.adicionar_peca(traseira)

    # Fundo da Gaveta
    larg_fundo = larg_interna_gaveta + (prof_rasgo * 2)
    prof_fundo = d_gaveta - (esp * 2) + (prof_rasgo * 2)

    fundo_gav = Peca.new(modulo_pai.id_modulo, :fundo_gaveta, lbl_fnd, larg_fundo, prof_fundo, esp_fnd)
    fundo_gav.id_vinculo_structure = id_vinculo_gaveta
    z_fundo = z_inicial + 15.0
    fundo_gav.posicao_relativa = { pos_x: x_inicial + esp - prof_rasgo, pos_y: y_inicial + esp - prof_rasgo, pos_z: z_fundo }
    modulo_pai.adicionar_peca(fundo_gav)

    return modulo_pai
  end

  def self.fabricar_caixote_sapateira(modulo, id_vinculo, largura_vao, prof_livre, z_pos, x_pos, opcoes = {})
    esp = modulo.parametros_globais[:espessura_mdf] || 15.0
    mat_caixa = modulo.parametros_globais[:material_caixaria] || "generico_branco_tx"
    gap_int = modulo.parametros_globais[:gap_int] || 4.0

    # Folga lateral para corrediças (13mm de cada lado = 26mm total)
    folga_corredica = opcoes[:folga_corredica] || 26.0
    largura_caixote = largura_vao - folga_corredica
    
    # Profundidade comercial ajustada em múltiplos de 50mm
    prof_util = ((prof_livre - 10.0) / 50.0).floor * 50.0
    prof_util = 250.0 if prof_util < 250.0

    alt_frente_sap = 80.0 # Altura exata da frente baixa (8cm)
    alt_tras_sap   = 70.0 # Altura exata da traseira baixa (7cm)
    tamanho_frente = largura_vao - (gap_int * 2.0) # Largura comercial da frente da sapateira
    x_inicial = x_pos + folga_corredica / 2.0
    recuo_y = opcoes[:recuo_frente] || 50.0

    # 1. Frente Baixa da Sapateira (8cm)
    frt = Peca.new(modulo.id_modulo, :frente_sapateira_interna, "Frente Sapateira", tamanho_frente, esp, alt_frente_sap)
    frt.definir_material!(mat_caixa)
    frt.id_vinculo_structure = id_vinculo
    frt.posicao_relativa = { pos_x: x_inicial - gap_int * 2.0, pos_y: recuo_y, pos_z: z_pos }
    frt.fita_borda = { superior: mat_caixa, inferior: mat_caixa, direita: mat_caixa, esquerda: mat_caixa }
    modulo.adicionar_peca(frt)

    # 2. Traseira Baixa da Sapateira (7cm)
    tras = Peca.new(modulo.id_modulo, :traseira_sapateira_interna, "Traseira Sapateira", largura_caixote, esp, alt_tras_sap)
    tras.definir_material!(mat_caixa)
    tras.id_vinculo_structure = id_vinculo
    tras.posicao_relativa = { pos_x: x_inicial, pos_y: recuo_y + prof_util - esp, pos_z: z_pos }
    tras.fita_borda = { superior: mat_caixa, inferior: mat_caixa, direita: mat_caixa, esquerda: mat_caixa }
    modulo.adicionar_peca(tras)

    # 3. Base / Prateleira Deslizante (Encaixada perfeitamente entre frente e traseira)
    prof_base = prof_util - (esp * 2)
    base = Peca.new(modulo.id_modulo, :base_sapateira_interna, "Base Sapateira", largura_caixote, prof_base, esp)
    base.definir_material!(mat_caixa)
    base.id_vinculo_structure = id_vinculo
    base.posicao_relativa = { pos_x: x_inicial, pos_y: recuo_y + esp, pos_z: z_pos + esp }
    base.fita_borda = { direita: mat_caixa, esquerda: mat_caixa }
    modulo.adicionar_peca(base)
  end
end