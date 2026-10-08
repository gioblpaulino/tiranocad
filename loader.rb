# ==============================================================================
# TIRANOGIO CAD - CARREGADOR PRINCIPAL SEGURO (TiranoGioCAD/loader.rb)
# ==============================================================================

# Adiciona o diretório atual ao $LOAD_PATH para evitar quebras se a pasta for renomeada
diretorio_raiz = File.expand_path('..', __dir__)
$LOAD_PATH.unshift(diretorio_raiz) unless $LOAD_PATH.include?(diretorio_raiz)

# 1. CARREGAMENTO DOS MODELOS DE DADOS UNIVERSAIS (A Base de Tudo)
require 'TiranoGioCAD/Modelos/Peca'
require 'TiranoGioCAD/Modelos/Modulo'
require 'TiranoGioCAD/Regras/NoEspacial'

# 2. CARREGAMENTO DOS BANCOS DE DADOS E CATÁLOGOS
require 'TiranoGioCAD/Regras/GerenciadorPerfis'
require 'TiranoGioCAD/Regras/CatalogoFerragens'
require 'TiranoGioCAD/Regras/CatalogoMateriais'

# 3. CARREGAMENTO DOS MOTORES PARAMÉTRICOS INTERNOS
require 'TiranoGioCAD/Regras/ConstrutorAmbiente'
require 'TiranoGioCAD/Regras/ConstrutorAereo'
require 'TiranoGioCAD/Regras/ConstrutorInferior'
require 'TiranoGioCAD/Regras/ConstrutorAlto'
require 'TiranoGioCAD/Regras/ConstrutorGavetas'
require 'TiranoGioCAD/Regras/ConstrutorPortaTempero'
require 'TiranoGioCAD/Regras/ConstrutorInternos'
require 'TiranoGioCAD/Regras/ConstrutorFrentes'

# 4. CARREGAMENTO DOS ORQUESTRADORES DE REGRAS (Dependem dos construtores acima)
require 'TiranoGioCAD/Regras/OrquestradorUsinagens'
require 'TiranoGioCAD/Regras/OrquestradorModulo'

# 5. CARREGAMENTO DOS MOTORES DE VISUALIZAÇÃO 3D E INTERFACE
require 'TiranoGioCAD/Regras/RenderizadorMateriais'
require 'TiranoGioCAD/Sketchup/Renderizador'
require 'TiranoGioCAD/Sketchup/Painel'
require 'TiranoGioCAD/Sketchup/Menu'

puts "🚀 Motor TiranoGio V8 reordenado e carregado com sucesso absoluto!"