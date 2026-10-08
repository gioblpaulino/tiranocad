# ==============================================================================
# MODELO DE DADOS UNIVERSAL: PEÇA (Peca.rb)
# ==============================================================================
require 'securerandom'

class Peca
  # Definindo todos os atributos (metadados) que a peça pode ter
  attr_accessor :id_peca, :id_pai, :categoria_industrial, :nome_comercial
  attr_accessor :dimensoes, :material, :tem_veio, :fita_borda
  attr_accessor :posicao_relativa, :usinagens
  
  # Atributo de vínculo para caixotes (Gavetas/Temperos) 
  attr_accessor :id_vinculo_structure


  def initialize(id_pai, categoria_industrial, nome_comercial, comp_x, larg_y, esp_z)
    @id_peca = SecureRandom.uuid # ID Único universal
    @id_pai = id_pai             # A quem essa peça pertence (O Módulo ou outra peça)
    
    # Leitura da Engenharia (Imutável)
    @categoria_industrial = categoria_industrial # Ex: "LATERAL_ESQUERDA", "PORTA"
    
    # Nome genérico da peça (customizável):
    @nome_comercial = nome_comercial # Nome comercial da peça

    # Geometria base
    @dimensoes = { x: comp_x, y: larg_y, z: esp_z }
    
    # Propriedades Físicas e de Acabamento
    @material = "generico_branco_tx"
    @tem_veio = false
    
    # Dicionário de Fita de Borda (0 = Sem fita, 1 = Fita 0.45mm, 2 = Fita 1mm, etc)
    @fita_borda = {
      superior: 0, 
      inferior: 0, 
      esquerda: 0, 
      direita: 0
    }

    # Posição Relativa (O SEGREDO PARA O SEU SERVIDOR 3D FLASK FICAR LEVE)
    # Diz onde a peça está em relação ao PAI dela.
    @posicao_relativa = {
      pos_x: 0.0, pos_y: 0.0, pos_z: 0.0,
      rot_x: 0.0, rot_y: 0.0, rot_z: 0.0
    }

    # Dicionário de Usinagens (Inspirado no Cut Pro)
    @usinagens = {
      furos: [],
      rasgos: []
    }

    @id_vinculo_structure = nil
  end

  # Método auxiliar para atualizar o material e herdar a propriedade do veio do MDF
  def definir_material!(id_material)
    @material = id_material
    dados_mat = CatalogoMateriais.obter(id_material)
    if dados_mat
      @tem_veio = dados_mat['tem_veio'] || false
    end
  end
  
  # Método para adicionar um furo traduzido pro nosso idioma
  def adicionar_furo(x, y, diametro, profundidade, face_normal = "FACE_PRINCIPAL")
    @usinagens[:furos] << {
      id_furo: SecureRandom.uuid,
      x: x,
      y: y,
      diametro: diametro,
      profundidade: profundidade,
      face_normal: face_normal # Ex: FACE_PRINCIPAL, FACE_TRASEIRA, TOPO_SUP, TOPO_INF
    }
  end

  # Fallback temporário para manter retrocompatibilidade com o Renderizador atual
  def papel_estrutural
    @categoria_industrial.to_s.upcase
  end

end