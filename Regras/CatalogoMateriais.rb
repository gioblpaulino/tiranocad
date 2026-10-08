# ==============================================================================
# REVISÃO: CATALOGO DE MATERIAIS MDF (Regras/CatalogoMateriais.rb)
# ==============================================================================
require 'json'

class CatalogoMateriais
  @@materiais = {}

  def self.carregar_catalogos
    @@materiais.clear
    raiz_plugin = File.expand_path('..', __dir__)
    diretorio_json = File.join(raiz_plugin, 'Catalogos', 'Materiais', '*.json')

    Dir.glob(diretorio_json) do |caminho_arquivo|
      begin
        conteudo = File.read(caminho_arquivo, encoding: 'UTF-8')
        dados = JSON.parse(conteudo)
        fabricante = dados['fabricante']

        if dados['padroes'] && dados['padroes'].is_a?(Array)
          dados['padroes'].each do |padrao|
            id = padrao['id']
            @@materiais[id] = padrao.merge('fabricante' => fabricante)
          end
        end
      rescue => e
        puts "⚠️ CatalogoMateriais: Erro ao ler #{caminho_arquivo}: #{e.message}"
      end
    end

    puts "🎨 CatalogoMateriais: #{@@materiais.size} padrões de MDF carregados com sucesso!"
  end

  def self.obter(id_material)
    carregar_catalogos if @@materiais.empty?
    id_str = id_material.to_s
    
    # 🚀 CORREÇÃO: Busca por ID, fallback para generico_branco_tx ou primeiro do catálogo

    @@materiais[id_str] || @@materiais["generico_branco_tx"] || @@materiais.values.first || {
      "id" => "generico_branco_tx",
      "nome" => "Branco TX",
      "fabricante" => "Genérico",
      "cor_rgb" => [245, 245, 245],
      "tem_veio" => false
    }
  end

  def self.todos
    carregar_catalogos if @@materiais.empty?
    @@materiais
  end
end