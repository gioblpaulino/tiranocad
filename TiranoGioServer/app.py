# ==============================================================================
# BACK-END CORRIGIDO + COPILOTO: CORE DO SERVIDOR FLASK (app.py)
# ==============================================================================
from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
import glob
import os
import json

# Importação da SDK oficial do Gemini
from google import genai
from google.genai import types

app = Flask(__name__, template_folder="templates", static_folder="static")
# Permite requisições CORS de qualquer origem, essencial para comunicação com o SketchUp
CORS(app)

# Inicializa o cliente do Gemini usando a chave de API das variáveis de ambiente
gemini_client = genai.Client(
    api_key="AQ.Ab8RN6JBi1sljNlw2PIE-hPN-7zCT8WOaJUndYXBoMdnBYOdKw"
)

# Banco de dados em memória para os módulos processados
PROJETO_ATIVO = {}


@app.route("/api/modulo", methods=["POST"])
def receber_modulo():
    global PROJETO_ATIVO
    try:
        dados_modulo = request.get_json()
        if not dados_modulo:
            return jsonify({"status": "erro", "mensagem": "Payload ausente"}), 400

        # 🚀 CORREÇÃO: Normalização estrita de ID para String com preenchimento de zeros (Zeros à esquerda)
        # Garante que "1", 1 ou "001" sejam salvos uniformemente como "001"
        raw_id = dados_modulo.get("id_modulo", "001")
        id_mod = str(raw_id).zfill(3)

        # Sobreescreve o ID normalizado dentro do próprio payload para manter a consistência
        dados_modulo["id_modulo"] = id_mod

        PROJETO_ATIVO[id_mod] = dados_modulo
        print(
            f"🚀 Módulo {id_mod} ({dados_modulo.get('nome_projeto', 'Sem Nome')}) sincronizado com sucesso!"
        )
        return jsonify({"status": "sucesso", "guid": dados_modulo.get("guid", "")}), 200
    except Exception as e:
        return jsonify({"status": "erro", "mensagem": str(e)}), 500


@app.route('/api/modulo/<id_modulo>', methods=['GET'])
def obter_modulo(id_modulo):
    global PROJETO_ATIVO
    # Normaliza a busca com zeros à esquerda
    id_busca = str(id_modulo).zfill(3)

    modulo = PROJETO_ATIVO.get(id_busca)

    if modulo:
        return jsonify(modulo), 200

    # Se não encontrar o ID específico, faz o fallback para o primeiro módulo cadastrado
    if PROJETO_ATIVO:
        primeiro_id = list(PROJETO_ATIVO.keys())[0]
        print(f"⚠️ Módulo {id_busca} não localizado. Forçando fallback para: {primeiro_id}")
        return jsonify(PROJETO_ATIVO[primeiro_id]), 200

    return jsonify({"status": "erro", "mensagem": f"Módulo {id_busca} não localizado no servidor"}), 404


@app.route("/visualizador/<id_modulo>")
def renderizar_visualizador(id_modulo):
    # 🚀 CORREÇÃO: Normaliza o ID enviado para o template HTML
    id_limpo = str(id_modulo).zfill(3)
    return render_template("visualizador.html", id_modulo=id_limpo)


@app.route("/api/materiais", methods=["GET"])
def listar_materiais():
    catalogos = []
    caminho_materiais = os.path.join(
        os.path.dirname(__file__), "Catalogos", "Materiais", "*.json"
    )

    for arq in glob.glob(caminho_materiais):
        try:
            with open(arq, "r", encoding="utf-8") as f:
                catalogos.append(json.load(f))
        except Exception as e:
            print(f"Erro ao carregar {arq}: {e}")

            return jsonify(catalogos)

        # ==============================================================================
        # 🚀 ENDPOINT DO COPILOTO DE ENGENHARIA PARAMÉTRICA (app.py)
        # ==============================================================================


PROMPT_SISTEMA_COPILOTO = """
        Você é o Copiloto de Engenharia do TiranoGio CAD.
        Sua função é interpretar comandos em linguagem natural do usuário e converter em modificações na Árvore de Partição Espacial (BSP) de um móvel de marcenaria.

        ESTRUTURA DO JSON BSP ESPERADA:
            - id: string única do nó (ex: "V", "V_A", "V_B")
            - split: "v" (Corte Vertical / Divisória) | "h" (Corte Horizontal / Prateleira Fixa) | null (Vão Livre / Nó Folha)
            - splitRatio: float entre 0.1 e 0.9 (padrão 0.5 para divisão no meio)
            - filhoA: objeto do nó da esquerda ou inferior (com a mesma estrutura)
            - filhoB: objeto do nó da direita ou superior (com a mesma estrutura)
            - dados (apenas nos nós onde split é null):

                - frente: "nenhuma" | "portas" | "gavetas" | "porta_tempero" | "gavetas_internas" | "sapateiras_internas"
                - qtd_frente: integer (quantidade de frentes/portas/gavetas, padrão 1)
                - sentido_porta: "esquerda" | "direita" (apenas se frente for "portas" e qtd_frente for 1)
                - qtd_prat: integer (quantidade de prateleiras móveis/livres no vão, padrão 0)

                REGRAS TÉCNICAS DE MARCENARIA:
                    1. Divisões verticais (v) criam filhoA (esquerda) e filhoB (direita).
                    2. Divisões horizontais (h) criam filhoA (inferior) e filhoB (superior).
                    3. Mantenha os IDs dos nós legíveis e únicos.
                    4. Mantenha a integridade dos nós e altere apenas o que o usuário solicitou.

                    Sua resposta DEVE ser estritamente um JSON válido no esquema especificado.
                    """


@app.route("/api/copiloto/interpretar", methods=["POST"])
def interpretar_comando_copiloto():
    try:
        payload = request.get_json()
        comando_usuario = payload.get("comando", "")
        arvore_atual = payload.get("arvore_atual", {})

        # Montamos o prompt de instrução com o contexto atual + pedido do usuário
        prompt_instrucao = f"""
        ÁRVORE BSP ATUAL DO MÓDULO:
            {json.dumps(arvore_atual, indent=2)}

            COMANDO DO MARCENEIRO:
                "{comando_usuario}"

                Altere a Árvore BSP para atender exatamente ao pedido do marceneiro.
                """

        # Chamada oficial para a SDK do Gemini
        response = gemini_client.models.generate_content(
            model="gemini-3.8-flash",
            contents=prompt_instrucao,
            config=types.GenerateContentConfig(
                system_instruction=PROMPT_SISTEMA_COPILOTO,
                response_mime_type="application/json",  # Força a IA a devolver estritamente JSON
                temperature=0.2,  # Baixa temperatura = respostas técnicas e obedientes
            ),
        )

        arvore_bsp_gerada = json.loads(response.text)

        return jsonify({"status": "sucesso", "arvore_bsp": arvore_bsp_gerada}), 200

    except Exception as e:
        print(f"❌ Erro no Copiloto: {e}")
        return jsonify({"status": "erro", "mensagem": str(e)}), 500

if __name__ == "__main__":
        # Roda em modo debug na porta 5000 padrão
        app.run(debug=True, port=5000)
