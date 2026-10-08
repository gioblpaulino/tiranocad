# ==============================================================================
# MOTOR DE REGRAS: ORQUESTRADOR DE USINAGENS V3 (Regras/OrquestradorUsinagens.rb)
# Varredura Corretiva: Alinhamento de Eixos CNC e Alturas de Corrediça
# ==============================================================================
require_relative 'CatalogoFerragens'

class OrquestradorUsinagens
  def self.processar(modulo)
    @catalogo = CatalogoFerragens.obter
    pecas = modulo.pecas
    puts "🔍 Iniciando Radar de Usinagens no Módulo: #{modulo.nome_amigavel}"

    # Captura os parâmetros dinâmicos de fábrica injetados pelo OrquestradorModulo
    prof_rasgo = modulo.parametros_globais[:prof_rasgo_dinamico] || 8.0
    larg_rasgo = modulo.parametros_globais[:largura_canal_dinamico] || 7.0
    recuo_fnd = modulo.parametros_globais[:recuo_fundo] || 15.0

    # 🚀 BLINDAGEM DE FAMÍLIA: Aéreos já possuem usinagem nativa controlada
    if modulo.familia == "MODULO_AEREO"
      puts "✈️ Módulo Aéreo detectado: Ignorando radar estrutural externo."
      processar_apenas_internos_aereo(modulo)
      processar_rasgos_fundo_dinamico(modulo, pecas, prof_rasgo, larg_rasgo, recuo_fnd)
      puts "✅ Radar de Usinagens para Aéreo finalizado!"
      return
    end

    # ==========================================================================
    # RADAR COMPLETO VIA CATEGORIAS DE ENGENHARIA (Para Inferiores, Torres e Roupeiros)
    # ==========================================================================
    verticais = pecas.select { |p| [:lateral_esquerda, :lateral_direita, :divisoria_vertical].include?(p.categoria_industrial) }
    horizontais_fix = pecas.select { |p| [:base_inferior, :base_superior, :prateleira_fixa].include?(p.categoria_industrial) }
        
    prat_livres = pecas.select { |p| p.categoria_industrial.to_s.start_with?("prateleira_livre") }
    portas = pecas.select { |p| [:porta_giro_esquerda, :porta_giro_direita].include?(p.categoria_industrial) }
    frentes_gav = pecas.select { |p| [:frente_gaveta, :frente_gavetaao].include?(p.categoria_industrial) }
        
    lats_gaveta = pecas.select { |p| [:lateral_gaveta, :lateral_gaveta_esquerda, :lateral_gaveta_direita].include?(p.categoria_industrial) }
    transv_gaveta = pecas.select { |p| [:ctrf_gaveta, :traseira_gaveta].include?(p.categoria_industrial) }
        
    y_panels_temp = pecas.select { |p| [:traseira_porta_tempero, :contra_frente_tempero].include?(p.categoria_industrial) }
    x_panels_temp = pecas.select { |p| [:base_porta_tempero, :prateleira_interno_tempero].include?(p.categoria_industrial) }

    # SESSÃO A: ESTRUTURA EXTERNA (Respeitando o Perfil Ativo do Usuário)
    perfil_nome = modulo.parametros_globais[:perfil_montagem] || "Padrao_Gemini"
    perfil_ativo = GerenciadorPerfis.obter_perfil(perfil_nome)
    usar_minifix = (perfil_ativo[:tipo_montagem_caixa] == "Minifix")

    horizontais_fix.each do |horiz|
      verticais.each do |vert|
        encosta_esq = (horiz.posicao_relativa[:pos_x] - (vert.posicao_relativa[:pos_x] + vert.dimensoes[:x])).abs < 0.1
        encosta_dir = ((horiz.posicao_relativa[:pos_x] + horiz.dimensoes[:x]) - vert.posicao_relativa[:pos_x]).abs < 0.1
        z_dentro = horiz.posicao_relativa[:pos_z] >= vert.posicao_relativa[:pos_z] && horiz.posicao_relativa[:pos_z] <= (vert.posicao_relativa[:pos_z] || vert.posicao_relativa[:pos_z] + vert.dimensoes[:z])

        if z_dentro
          if usar_minifix
            aplicar_minifix_cavilha(modulo, vert, horiz, :face_direita) if encosta_esq
            aplicar_minifix_cavilha(modulo, vert, horiz, :face_esquerda) if encosta_dir
          else
            aplicar_parafuso_soberbo(modulo, vert, horiz, :face_direita) if encosta_esq
            aplicar_parafuso_soberbo(modulo, vert, horiz, :face_esquerda) if encosta_dir
          end
        end
      end
    end

    # SESSÃO B: GAVETAS INTERNAS (Cruzamento Assegurado via UUID de Vínculo Estrutural)
    transv_gaveta.each do |transv|
      lats_gaveta.each do |lat|
        if transv.id_vinculo_structure == lat.id_vinculo_structure && !transv.id_vinculo_structure.nil?
          encosta_esq = (transv.posicao_relativa[:pos_x] - (lat.posicao_relativa[:pos_x] + lat.dimensoes[:x])).abs < 0.1
          encosta_dir = ((transv.posicao_relativa[:pos_x] + transv.dimensoes[:x]) - lat.posicao_relativa[:pos_x]).abs < 0.1
          aplicar_furos_gaveta(modulo, lat, transv) if encosta_esq || encosta_dir
        end
      end
    end

    # SESSÃO C: PORTA TEMPERO INTERNO (Vínculo Estrutural Concreto)
    x_panels_temp.each do |x_pan|
      y_panels_temp.each do |y_pan|
        if x_pan.id_vinculo_structure == y_pan.id_vinculo_structure && !x_pan.id_vinculo_structure.nil?
          encosta_frente = (x_pan.posicao_relativa[:pos_y] - (y_pan.posicao_relativa[:pos_y] + y_pan.dimensoes[:y])).abs < 0.1
          encosta_fundo = ((x_pan.posicao_relativa[:pos_y] + x_pan.dimensoes[:y]) - y_pan.posicao_relativa[:pos_y]).abs < 0.1
          aplicar_furos_tempero(modulo, y_pan, x_pan) if encosta_frente || encosta_fundo
        end
      end
    end

    # SESSÃO D: ACESSÓRIOS E PRATELEIRAS DINÂMICAS
    processar_acessorios_comuns(modulo, prat_livres, verticais, frentes_gav, portas)
        
    # SESSÃO E: RADAR DO CANAL DE FUNDO
    processar_rasgos_fundo_dinamico(modulo, pecas, prof_rasgo, larg_rasgo, recuo_fnd)

    puts "✅ Radar de Usinagens finalizado com sucesso!"
  end

  def self.processar_rasgos_fundo_dinamico(modulo, pecas, prof_rasgo, larg_rasgo, recuo_fnd)
    fundo = pecas.find { |p| p.categoria_industrial == :fundo_costa }
    
    pecas.each do |peca|
      categoria = peca.categoria_industrial
      next if categoria == :fundo_costa || categoria.to_s.include?("porta") || categoria.to_s.include?("frente")
    
      if [:lateral_gaveta, :lateral_gaveta_esquerda, :lateral_gaveta_direita].include?(categoria)
        peca.usinagens[:rasgos] << {
          tipo: "CANAL_GAVETA_Y", pos_z_local: 15.0, largura: larg_rasgo, profundidade: prof_rasgo
        }
        next
      elsif [:ctrf_gaveta, :traseira_gaveta, :contra_frente_tempero, :traseira_porta_tempero].include?(categoria)
        peca.usinagens[:rasgos] << {
          tipo: "CANAL_GAVETA_X", pos_z_local: 15.0, largura: larg_rasgo, profundidade: prof_rasgo
        }
        next
      elsif categoria.to_s.include?("haste_protecao") || categoria == :divisoria_vertical || categoria == :prateleira_fixa
        # 🚀 CORREÇÃO DE CHÃO DE FÁBRICA: Divisórias e prateleiras fixas morrem no fundo e NÃO recebem canal
        next
      end
    
      if fundo
        y_rasgo = fundo.posicao_relativa[:pos_y]
        fim_da_peca = peca.posicao_relativa[:pos_y] + peca.dimensoes[:y]
        next if fim_da_peca < (y_rasgo - 5.0)
      
        pos_y_local = y_rasgo - peca.posicao_relativa[:pos_y]
        
        # Aplica a usinagem estritamente nas laterais externas e bases externas da caixaria
        if [:lateral_esquerda, :lateral_direita].include?(categoria)
          peca.usinagens[:rasgos] << {
            tipo: "CANAL_FUNDO_V", pos_y: pos_y_local, largura: larg_rasgo, profundidade: prof_rasgo
          }
        elsif [:base_inferior, :base_superior].include?(categoria)
          peca.usinagens[:rasgos] << {
            tipo: "CANAL_FUNDO_H", pos_y: pos_y_local, largura: larg_rasgo, profundidade: prof_rasgo
          }
        end
      end
    end
  end

  def self.processar_apenas_internos_aereo(modulo)
    pecas = modulo.pecas
    verticais = pecas.select { |p| [:lateral_esquerda, :lateral_direita, :divisoria_vertical].include?(p.categoria_industrial) }
    prat_livres = pecas.select { |p| p.categoria_industrial.to_s.start_with?("prateleira_livre") }
    portas = pecas.select { |p| [:porta_giro_esquerda, :porta_giro_direita].include?(p.categoria_industrial) }
    frentes_gav = pecas.select { |p| [:frente_gaveta, :frente_gavetaao].include?(p.categoria_industrial) }

    processar_acessorios_comuns(modulo, prat_livres, verticais, frentes_gav, portas)
  end

  def self.processar_acessorios_comuns(modulo, prat_livres, verticais, frentes_gav, portas)
    prat_livres.each do |livre|
      verticais.each do |vert|
        encosta_esq = (livre.posicao_relativa[:pos_x] - (vert.posicao_relativa[:pos_x] + vert.dimensoes[:x])).abs < 5.0 
        encosta_dir = ((livre.posicao_relativa[:pos_x] + livre.dimensoes[:x]) - vert.posicao_relativa[:pos_x]).abs < 5.0
        z_dentro = livre.posicao_relativa[:pos_z] >= vert.posicao_relativa[:pos_z] && livre.posicao_relativa[:pos_z] <= (vert.posicao_relativa[:pos_z] + vert.dimensoes[:z])

        if z_dentro
          categoria_str = livre.categoria_industrial.to_s
          if categoria_str.include?("minifix")
            aplicar_minifix_cavilha(modulo, vert, livre, :face_direita) if encosta_esq
            aplicar_minifix_cavilha(modulo, vert, livre, :face_esquerda) if encosta_dir
          elsif categoria_str.include?("cavilha")
            aplicar_apenas_cavilha(modulo, vert, livre, :face_direita) if encosta_esq
            aplicar_apenas_cavilha(modulo, vert, livre, :face_esquerda) if encosta_dir
          elsif categoria_str.include?("cantoneira")
            puts " 🔧 Cantoneira detectada: Furação suspensa na CNC."
          else
            aplicar_pino(modulo, vert, livre, :face_direita) if encosta_esq
            aplicar_pino(modulo, vert, livre, :face_esquerda) if encosta_dir
          end
        end
      end
    end

    frentes_gav.each do |frente|
      verticais.each do |vert|
        face_dir_vert = vert.posicao_relativa[:pos_x] + vert.dimensoes[:x]
        face_esq_vert = vert.posicao_relativa[:pos_x]
        face_dir_frente = frente.posicao_relativa[:pos_x] + frente.dimensoes[:x]

        aplicar_corredica(modulo, frente, vert, :face_direita) if (frente.posicao_relativa[:pos_x] - face_dir_vert).abs < 25.0
        aplicar_corredica(modulo, frente, vert, :face_esquerda) if (face_dir_frente - face_esq_vert).abs < 25.0
      end
    end

    portas.each do |porta|
      is_esq = porta.categoria_industrial == :porta_giro_esquerda
      verticais.each do |vert|
        if is_esq
          face_dir_vert = vert.posicao_relativa[:pos_x] + vert.dimensoes[:x]
          aplicar_dobradica(modulo, porta, vert, :face_direita, is_esq) if (porta.posicao_relativa[:pos_x] - face_dir_vert).abs < 25.0
        else
          face_esq_vert = vert.posicao_relativa[:pos_x]
          face_dir_porta = porta.posicao_relativa[:pos_x] + porta.dimensoes[:x]
          aplicar_dobradica(modulo, porta, vert, :face_esquerda, is_esq) if (face_dir_porta - face_esq_vert).abs < 25.0
        end
      end
    end
  end

  def self.obter_face_furo(vertical, face_atingida)
    categoria = vertical.categoria_industrial
    
    if categoria == :divisoria_vertical
      # Para divisórias centrais, a face atingida é diretamente a FACE_DIREITA ou FACE_ESQUERDA
      return (face_atingida == :face_direita) ? "FACE_EXTERNA" : "FACE_INTERNA"
    end
    is_dir = (categoria == :lateral_direita)
    (face_atingida == :face_direita) ? (is_dir ? "FACE_EXTERNA" : "FACE_INTERNA") : (is_dir ? "FACE_INTERNA" : "FACE_EXTERNA")
  end

  def self.aplicar_minifix_cavilha(modulo, vertical, horizontal, face_atingida)
    cfg_pos = @catalogo[:fixadores][:regras_posicionamento]
    cfg_mini = @catalogo[:fixadores][:minifix_15mm]
    cfg_cavi = @catalogo[:fixadores][:cavilha_8x30]

    dist_tras = modulo.parametros_globais[:dist_furo_tras] || cfg_pos[:distancia_traseira]
    dist_front = modulo.parametros_globais[:dist_furo_front] || cfg_pos[:distancia_frontal]
    max_vao = modulo.parametros_globais[:dist_furo_max_vao] || 250.0

    y_offset = horizontal.posicao_relativa[:pos_y] - vertical.posicao_relativa[:pos_y]
    comp_y = horizontal.dimensoes[:y]

    pontos_y = calcular_pontos_furacao(y_offset, comp_y, dist_tras, dist_front, max_vao)

    # 🚀 CENTRALIZAÇÃO DINÂMICA: Calcula o centro exato da chapa (15mm, 18mm ou 25mm)
    z_furo = horizontal.posicao_relativa[:pos_z] - vertical.posicao_relativa[:pos_z] + (horizontal.dimensoes[:z] / 2.0)
    face_furo_vert = obter_face_furo(vertical, face_atingida)
    x_caneco = (face_atingida == :face_direita) ? cfg_mini[:recuo_caneco] : (horizontal.dimensoes[:x] - cfg_mini[:recuo_caneco])

    pontos_y.each do |y_furo|
      vertical.adicionar_furo(y_furo, z_furo, cfg_mini[:diametro_pino], cfg_mini[:prof_pino], face_furo_vert)
      vertical.adicionar_furo(y_furo + cfg_pos[:distancia_cavilha], z_furo, cfg_cavi[:diametro], cfg_cavi[:prof_face], face_furo_vert)
      horizontal.adicionar_furo(x_caneco, y_furo, cfg_mini[:diametro_caneco], cfg_mini[:prof_caneco], "FACE_INFERIOR")
    end
  end

  
  def self.calcular_pontos_furacao(inicio_eixo, comprimento_total, dist_tras, dist_front, max_vao)
    pontos = []
    furo_1 = inicio_eixo + dist_tras
    furo_final = inicio_eixo + comprimento_total - dist_front

    if furo_final <= furo_1
      pontos << inicio_eixo + (comprimento_total / 2.0)
    else
      pontos << furo_1
      vao_livre = furo_final - furo_1
      qtd_espacos = (vao_livre / max_vao).ceil
      qtd_furos_meio = qtd_espacos - 1
      
      if qtd_furos_meio > 0
        passo = vao_livre / qtd_espacos.to_f
        (1..qtd_furos_meio).each do |i|
          pontos << (furo_1 + (passo * i))
        end
      end
      pontos << furo_final
    end
    return pontos
  end

  def self.aplicar_apenas_cavilha(modulo, vertical, horizontal, face_atingida)
    cfg_pos = @catalogo[:fixadores][:regras_posicionamento]
    cfg_cavi = @catalogo[:fixadores][:cavilha_8x30]

    y_offset = horizontal.posicao_relativa[:pos_y] - vertical.posicao_relativa[:pos_y]
    y_furo_1 = y_offset + cfg_pos[:distancia_traseira]
    y_furo_2 = y_offset + horizontal.dimensoes[:y] - cfg_pos[:distancia_frontal]
    z_furo = horizontal.posicao_relativa[:pos_z] - vertical.posicao_relativa[:pos_z] + (horizontal.dimensoes[:z] / 2.0)

    face_furo_vert = obter_face_furo(vertical, face_atingida)

    vertical.adicionar_furo(y_furo_1, z_furo, cfg_cavi[:diametro], cfg_cavi[:prof_face], face_furo_vert)
    vertical.adicionar_furo(y_furo_2, z_furo, cfg_cavi[:diametro], cfg_cavi[:prof_face], face_furo_vert)
  end

  def self.aplicar_parafuso_soberbo(modulo, vertical, horizontal, face_atingida)
    cfg_pos = @catalogo[:fixadores][:regras_posicionamento]
    perfil_nome = modulo.parametros_globais[:perfil_montagem] || "Padrao_Gemini"
    perfil_ativo = GerenciadorPerfis.obter_perfil(perfil_nome)
    
    dist_front = modulo.parametros_globais[:dist_furo_front] || perfil_ativo.dig(:usinagem, :recuo_furo_padrao) || cfg_pos[:distancia_frontal]
    dist_tras  = modulo.parametros_globais[:dist_furo_tras]  || perfil_ativo.dig(:usinagem, :recuo_furo_padrao) || cfg_pos[:distancia_traseira]
    max_vao    = modulo.parametros_globais[:dist_furo_max_vao] || 250.0
    
    broca_parafuso = perfil_ativo.dig(:usinagem, :broca_parafusos) || 4.5
    folga_passante = perfil_ativo.dig(:usinagem, :folga_passante_parafuso) || 3.0
    
    y_offset = horizontal.posicao_relativa[:pos_y] - vertical.posicao_relativa[:pos_y]
    comp_y = horizontal.dimensoes[:y]
    
    pontos_y = calcular_pontos_furacao(y_offset, comp_y, dist_tras, dist_front, max_vao)
    
    z_furo = horizontal.posicao_relativa[:pos_z] - vertical.posicao_relativa[:pos_z] + (horizontal.dimensoes[:z] / 2.0) rescue 10.0
    face_furo_vert = obter_face_furo(vertical, face_atingida)
    
    prof_passante = vertical.dimensoes[:x] + folga_passante 

    pontos_y.each do |y_furo|
      vertical.adicionar_furo(y_furo, z_furo, broca_parafuso, prof_passante, face_furo_vert)
    end
  end

  def self.aplicar_furos_gaveta(modulo, lateral, transversal)
    dist_gav = modulo.parametros_globais[:dist_furo_gaveta]
    
    z_offset = transversal.posicao_relativa[:pos_z] - lateral.posicao_relativa[:pos_z]
    comp_z = transversal.dimensoes[:z]
    
    pontos_z = calcular_pontos_furacao(z_offset, comp_z, dist_gav, dist_gav, 150.0)
    
    y_offset = transversal.posicao_relativa[:pos_y] - lateral.posicao_relativa[:pos_y]
    y_furo = y_offset + (transversal.dimensoes[:y] / 2.0)
    prof = lateral.dimensoes[:x] + 1.0 

    pontos_z.each do |z_furo|
      lateral.adicionar_furo(y_furo, z_furo, 4.5, prof, "FACE_EXTERNA")
    end
  end

  def self.aplicar_furos_tempero(modulo, vertical_y, horizontal_x)
    x_offset = horizontal_x.posicao_relativa[:pos_x] - vertical_y.posicao_relativa[:pos_x]
    z_offset = horizontal_x.posicao_relativa[:pos_z] - vertical_y.posicao_relativa[:pos_z]
    z_furo = z_offset + (horizontal_x.dimensoes[:z] / 2.0)
    prof = vertical_y.dimensoes[:y] + 1.0 

    x_furo_1 = x_offset + 20.0
    x_furo_2 = x_offset + horizontal_x.dimensoes[:x] - 20.0
    vertical_y.adicionar_furo(x_furo_1, z_furo, 4.5, prof, "FACE_EXTERNA")
    vertical_y.adicionar_furo(x_furo_2, z_furo, 4.5, prof, "FACE_EXTERNA")
  end

  def self.aplicar_pino(modulo, vertical, livre, face_atingida)
    cfg_fix = @catalogo[:fixadores][:pino_prateleira]

    dist_tras = modulo.parametros_globais[:dist_furo_tras] || cfg_pos[:distancia_traseira]
    dist_front = modulo.parametros_globais[:dist_furo_front] || cfg_pos[:distancia_frontal]
    max_vao = modulo.parametros_globais[:dist_furo_max_vao] || 250.0

    y_offset = livre.posicao_relativa[:pos_y] - vertical.posicao_relativa[:pos_y]
    comp_y = livre.dimensoes[:y]
    
    pontos_y = calcular_pontos_furacao(y_offset, comp_y, dist_tras, dist_front, max_vao)

    z_furo = livre.posicao_relativa[:pos_z] - vertical.posicao_relativa[:pos_z] - 2.5 
    face_furo_vert = obter_face_furo(vertical, face_atingida)

    pontos_y.each do |y_furo|
      vertical.adicionar_furo(y_furo, z_furo, cfg_fix[:diametro], cfg_fix[:profundidade], face_furo_vert)
    end
  end

  # CORREÇÃO DE ALTURA SERRALHERIA: Sincroniza a furação com a elevação de +15mm nativa do caixote interno
  def self.aplicar_corredica(modulo, frente_gav, vertical, face_vertical)
    prof_caixa = vertical.dimensoes[:y]
    tamanho = prof_caixa >= 520 ? "500mm" : (prof_caixa >= 470 ? "450mm" : (prof_caixa >= 420 ? "400mm" : (prof_caixa >= 370 ? "350mm" : "300mm")))
    cfg = @catalogo[:corredicas][:telescopica][tamanho]
    
    perfil_nome = modulo.parametros_globais[:perfil_montagem] || "Padrao_Gemini"
    perfil_ativo = GerenciadorPerfis.obter_perfil(perfil_nome)
    cfg_gaveta = perfil_ativo[:gaveta] || {}

    elevacao_z = cfg_gaveta[:elevacao_caixote_z] || 15.0
    offset_trilho_z = cfg_gaveta[:offset_eixo_corredica_z] || 45.0

    z_abs = frente_gav.posicao_relativa[:pos_z] + elevacao_z + offset_trilho_z 
    z_local_vert = z_abs - vertical.posicao_relativa[:pos_z]
    face_furo_vert = obter_face_furo(vertical, face_vertical)

    cfg[:furos_y].each do |y_furo|
      vertical.adicionar_furo(y_furo, z_local_vert, cfg[:diametro_furo], cfg[:profundidade_furo], face_furo_vert)
    end
  end

  def self.calcular_qtd_dobradicas(h_porta, perfil_ativo)
    regras = perfil_ativo[:regras_dobradicas] || [
      { altura_max: 900.0, qtd: 2 },
      { altura_max: 1500.0, qtd: 3 },
      { altura_max: 2000.0, qtd: 4 },
      { altura_max: 99999.0, qtd: 5 }
    ]
    regra = regras.find { |r| h_porta <= r[:altura_max] }
    regra ? regra[:qtd] : 2
  end

  def self.aplicar_dobradica(modulo, porta, vertical, face_vertical, is_esq)
    cfg = @catalogo[:dobradicas][:reta_35mm]
    perfil_nome = modulo.parametros_globais[:perfil_montagem] || "Padrao_Gemini"  
    perfil_ativo = GerenciadorPerfis.obter_perfil(perfil_nome)
    h_porta = porta.dimensoes[:z]

    perfil_nome = modulo.parametros_globais[:perfil_montagem] || "Padrao_Gemini"
    perfil_ativo = GerenciadorPerfis.obter_perfil(perfil_nome)
    cfg_usinagem = perfil_ativo[:usinagem] || {}

    qtd_dobradicas = calcular_qtd_dobradicas(h_porta, perfil_ativo)

    x_caneco = is_esq ? cfg[:posicao_caneco] : (porta.dimensoes[:x] - cfg[:posicao_caneco])
    x_picote = is_esq ? (cfg[:posicao_caneco] + cfg[:afastamento_picote_caneco]) : (porta.dimensoes[:x] - cfg[:posicao_caneco] - cfg[:afastamento_picote_caneco])
    face_furo_vert = obter_face_furo(vertical, face_vertical)

    diametro_caneco = modulo.parametros_globais[:broca_canecos] || perfil_ativo.dig(:usinagem, :broca_canecos) || cfg[:diametro_caneco]
    prof_caneco = perfil_ativo.dig(:usinagem, :prof_caneco) || cfg[:profundidade_caneco]
    
    pontos_z = []
    z_recuo_borda = cfg_usinagem[:recuo_borda_dobradica] || 100.0

    if qtd_dobradicas == 2
      pontos_z << z_recuo_borda
      pontos_z << (h_porta - z_recuo_borda)
    else
      pontos_z << z_recuo_borda
      pontos_z << (h_porta - z_recuo_borda)
      divisores_vao = qtd_dobradicas - 1
      passo_distancia = (h_porta - (z_recuo_borda * 2)) / divisores_vao.to_f
      (1..(qtd_dobradicas - 2)).each do |i|
        pontos_z << (z_recuo_borda + (i * passo_distancia))
      end
    end

    pontos_z.each do |z_abs_porta|
      porta.adicionar_furo(x_caneco, z_abs_porta, diametro_caneco, prof_caneco, "FACE_INTERNA")
      dist_picote = cfg[:distancia_picotes] / 2.0
      porta.adicionar_furo(x_picote, z_abs_porta + dist_picote, cfg[:diametro_picote], cfg[:profundidade_picote], "FACE_INTERNA")
      porta.adicionar_furo(x_picote, z_abs_porta - dist_picote, cfg[:diametro_picote], cfg[:profundidade_picote], "FACE_INTERNA")

      z_abs_global = porta.posicao_relativa[:pos_z] + z_abs_porta
      z_local_vert = z_abs_global - vertical.posicao_relativa[:pos_z]
      y_calco = cfg[:afastamento_calco_borda]

      vertical.adicionar_furo(y_calco, z_local_vert + (cfg[:distancia_furos_calco] / 2.0), 5.0, 12.0, face_furo_vert)
      vertical.adicionar_furo(y_calco, z_local_vert - (cfg[:distancia_furos_calco] / 2.0), 5.0, 12.0, face_furo_vert)
    end
  end
  
end