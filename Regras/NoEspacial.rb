# ==============================================================================
# ÁRVORE BSP: NÓ ESPACIAL E ALGORITMO DE PARTIÇÃO (Regras/NoEspacial.rb)
# Revisado para Segurança Contra Flechas e Validação de Limite Industrial
# ==============================================================================

class NoEspacial
  attr_accessor :id, :x, :y, :z, :w, :h, :d
  attr_accessor :filho_a, :filho_b, :eixo_corte, :espessura_mdf
  attr_accessor :conteudo 

  VAO_MINIMO_ENGENHARIA = 50.0

  def initialize(id, x, y, z, w, h, d, espessura_mdf)
    @id = id
    @x = x; @y = y; @z = z
    @w = w; @h = h; @d = d
    @espessura_mdf = espessura_mdf
    @filho_a = nil; @filho_b = nil; @eixo_corte = nil
    @conteudo = {}
  end

  def cortar_vertical(largura_esq, id_esq = "#{@id}_E", id_dir = "#{@id}_D")
    largura_dir = @w - largura_esq - @espessura_mdf

    # 🚀 REVISÃO: Impede a criação de vãos menores que o limite físico mínimo
    return false if largura_esq < VAO_MINIMO_ENGENHARIA || largura_dir < VAO_MINIMO_ENGENHARIA
    return false if @w <= (largura_esq + @espessura_mdf)
 
    @eixo_corte = :vertical
    @filho_a = NoEspacial.new(id_esq, @x, @y, @z, largura_esq, @h, @d, @espessura_mdf)
    x_dir = @x + largura_esq + @espessura_mdf
    @filho_b = NoEspacial.new(id_dir, x_dir, @y, @z, largura_dir, @h, @d, @espessura_mdf)
 
    true
  end

  def cortar_horizontal(altura_inf, id_inf = "#{@id}_B", id_sup = "#{@id}_C")
    altura_sup = @h - altura_inf - @espessura_mdf

    # 🚀 REVISÃO: Proteção mecânica de vãos horizontais
    return false if altura_inf < VAO_MINIMO_ENGENHARIA || altura_sup < VAO_MINIMO_ENGENHARIA
    return false if @h <= (altura_inf + @espessura_mdf)
 
    @eixo_corte = :horizontal
    @filho_a = NoEspacial.new(id_inf, @x, @y, @z, @w, altura_inf, @d, @espessura_mdf)
    z_sup = @z + altura_inf + @espessura_mdf
    @filho_b = NoEspacial.new(id_sup, @x, @y, z_sup, @w, altura_sup, @d, @espessura_mdf)
 
    true
  end

  def folha?
    @filho_a.nil? && @filho_b.nil?
  end

  def obter_folhas(lista = [])
    if folha?
      lista << self
    else
      @filho_a.obter_folhas(lista) if @filho_a
      @filho_b.obter_folhas(lista) if @filho_b
    end
    lista
  end

  def buscar_no(id_alvo)
    return self if @id == id_alvo
    return nil if folha?
    encontrado_a = @filho_a.buscar_no(id_alvo)
    return encontrado_a if encontrado_a
    @filho_b.buscar_no(id_alvo)
  end
end