// ==============================================================================
// MÓDULO DO COPILOTO PARAMÉTRICO (static/js/copiloto.js)
// Comunicação entre a interface do usuário (voz/texto) e o endpoint Flask do Gemini.
// ==============================================================================

/**
 * Envia o comando em texto do usuário para o servidor Flask interpretar via IA.
 * @param {string} textoComando - O comando digitado ou reconhecido por voz.
 */
async function enviarComandoCopiloto(textoComando) {
    // 1. Resgata o estado atual da árvore BSP do front-end
    const arvoreAtual = (typeof obterEstadoArvoreAtual === 'function') 
        ? obterEstadoArvoreAtual() 
        : (window.arvoreBSPATUAL || {});

    console.log("🚀 Enviando comando ao Copiloto TiranoGio:", textoComando);

    try {
        // 2. Requisição assíncrona para a rota do Copiloto no Flask (app.py)
        const resposta = await fetch('/api/copiloto/interpretar', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                comando: textoComando,
                arvore_atual: arvoreAtual
            })
        });

        const resultado = await resposta.json();

        if (resultado.status === 'sucesso') {
            console.log("✅ Nova Árvore BSP recebida do Copiloto:", resultado.arvore_bsp);
            
            // 3. Atualiza o estado global da árvore BSP na aplicação
            window.arvoreBSPATUAL = resultado.arvore_bsp;

            // 4. Re-renderiza a visualização 2D (se o editor 2D estiver presente na página)
            if (typeof renderizarArvore === 'function') {
                if (typeof bspTree !== 'undefined') {
                    bspTree = resultado.arvore_bsp;
                }
                renderizarArvore();
            }

            // 5. Se estiver no visualizador 3D Web, atualiza o holograma
            renderizarArvoreBSP(resultado.arvore_bsp);

            // 6. Notifica o SketchUp via callback (caso a janela esteja aberta dentro do CAD)
            sincronizarComSketchUp(resultado.arvore_bsp);

        } else {
            alert("⚠️ Erro do Copiloto: " + (resultado.mensagem || "Não foi possível interpretar o comando."));
        }
    } catch (erro) {
        console.error("❌ Falha na comunicação com o servidor Flask:", erro);
        alert("❌ Falha ao conectar ao servidor Flask (app.py na porta 5000).");
    }
}

/**
 * Envia a nova árvore BSP gerada pela IA para o controlador Ruby no SketchUp (Painel.rb).
 * @param {Object} arvoreBSP - Árvore BSP estruturada recebida do Gemini.
 */
function sincronizarComSketchUp(arvoreBSP) {
    const jsonStr = JSON.stringify(arvoreBSP);
    
    // 1. Chamada oficial para a API de HtmlDialog do SketchUp
    if (typeof sketchup !== 'undefined' && typeof sketchup.receberArvoreCopiloto === 'function') {
        sketchup.receberArvoreCopiloto(jsonStr);
        console.log("📡 Árvore BSP enviada com sucesso ao SketchUp via sketchup.receberArvoreCopiloto!");
    } 
    // 2. Fallback para Chromium Embedded Framework / CEFQuery
    else if (window.cefQuery && typeof window.cefQuery === 'function') {
        window.cefQuery({
            request: 'receberArvoreCopiloto:' + jsonStr,
            onSuccess: function(response) {},
            onFailure: function(error_code, error_message) {}
        });
    } else {
        console.warn("⚠️ Ambiente SketchUp não detectado no contexto da página.");
    }
}

// Função chamada pelo botão da interface HTML
function dispararCopiloto() {
    const campoTexto = document.getElementById('txt-comando-copiloto');
    if (!campoTexto) return;

    const comando = campoTexto.value.trim();

    if (!comando) {
        alert("Digite um comando para o Copiloto!");
        return;
    }

    // Desabilita o campo temporariamente para dar feedback de processamento
    campoTexto.disabled = true;
    const textoOriginal = campoTexto.value;
    campoTexto.value = "🤖 Copiloto pensando...";

    // Envia para o servidor Flask
    enviarComandoCopiloto(comando)
        .then(() => {
            campoTexto.value = "";
            campoTexto.disabled = false;
        })
        .catch(() => {
            campoTexto.disabled = false;
            campoTexto.value = textoOriginal;
        });
}

// Obtém o estado da árvore atual para enviar como contexto à IA
function obterEstadoArvoreAtual() {
    if (typeof bspTree !== 'undefined') {
        return bspTree;
    }
    return window.arvoreBSPATUAL || {};
}

// Atualiza e re-renderiza o estado 3D
function renderizarArvoreBSP(arvoreBSP) {
    window.arvoreBSPATUAL = arvoreBSP;
    
    // Se a função de construir o móvel 3D existir no visualizador.js
    if (typeof construirMovelParametrico === 'function') {
        if (typeof pecasInterativas !== 'undefined') {
            pecasInterativas.length = 0;
        }
        
        // Se houver dados já existentes de um payload completo, preservamos a chamada
        if (window.dadosModuloAtual) {
            window.dadosModuloAtual.arvore_json = JSON.stringify(arvoreBSP);
            construirMovelParametrico(window.dadosModuloAtual);
        }
    }
}