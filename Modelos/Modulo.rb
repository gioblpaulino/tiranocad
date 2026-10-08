# ==============================================================================
# MODELO DE DADOS UNIVERSAL: MÓDULO (Regras/Modulo.rb)
# ==============================================================================
require 'securerandom'

class Modulo
  @@contador_modulos = 0
 
  attr_accessor :id_modulo, :guid_universal, :nome_amigavel, :familia
  attr_accessor :dimensoes_totais, :parametros_globais
  attr_accessor :pecas, :acessorios 

  def initialize(nome_amigavel, familia, w, h, d, parametros_customizados = {})
    @@contador_modulos += 1

    @id_modulo = format("%03d", @@contador_modulos)
    @guid_universal = SecureRandom.uuid

    @nome_amigavel = nome_amigavel
    @familia = familia
 
    @dimensoes_totais = { largura_x: w.to_f, altura_y: h.to_f, profundidade_z: d.to_f }
 
    # 🚀 ELIMINAÇÃO DOS MAGIC NUMBERS:
    # O módulo nasce sem valores estáticos embutidos. 
    # Ele recebe o dicionário de parâmetros do Perfil Ativo ou inicia como Hash limpo.
    @parametros_globais = parametros_customizados.dup

    @pecas = []
    @acessorios = []
  end

  def self.resetar_contador!
    @@contador_modulos = 0
  end

  def adicionar_peca(peca_nova)
    peca_nova.id_pai = @id_modulo
    @pecas << peca_nova
  end

  
  def para_hash
    {
      id_modulo: @id_modulo.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: ''),
      guid: @guid_universal.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: ''),
      nome_projeto: @nome_amigavel.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: ''),
      familia: @familia.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: ''),
      dimensoes_ocupadas: @dimensoes_totais,
      parametros: @parametros_globais,
      lista_de_pecas: @pecas.map { |peca| 
        {
          id_peca: peca.id_peca.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: ''),
          id_pai: peca.id_pai.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: ''),
          id_vinculo_structure: peca.id_vinculo_structure,
          categoria_industrial: peca.categoria_industrial.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: ''),
          nome_comercial: peca.nome_comercial.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: ''),
          dimensoes: peca.dimensoes,
          posicao_relativa: peca.posicao_relativa,
          usinagens: peca.usinagens
        }
      }
    }
  end
end