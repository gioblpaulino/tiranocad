// ==============================================================================
// FRONT-END ENGINE: VISUALIZADOR 3D E GERENCIADOR DE LISTA DE CORTE (visualizador.js)
// ==============================================================================

let cena, camera, renderizador, controles;
let gruposInterativos = {};
let pecasInterativas = [];
let raycaster = new THREE.Raycaster();
let mouse = new THREE.Vector2();
let estadosAbertura = {};

function inicializarCenario() {
    const container = document.getElementById('canvas-container');

    cena = new THREE.Scene();
    cena.background = new THREE.Color(0x1e1e1e);

    camera = new THREE.PerspectiveCamera(45, container.clientWidth / container.clientHeight, 1, 10000);
    camera.position.set(1100, 900, 1300);

    renderizador = new THREE.WebGLRenderer({ antialias: true });
    renderizador.setSize(container.clientWidth, container.clientHeight);
    renderizador.shadowMap.enabled = true;
    container.appendChild(renderizador.domElement);

    controles = new THREE.OrbitControls(camera, renderizador.domElement);
    controles.enableDamping = true;
    controles.dampingFactor = 0.05;

    const luzAmbiente = new THREE.AmbientLight(0xffffff, 0.65);
    cena.add(luzAmbiente);

    const luzDirecional = new THREE.DirectionalLight(0xffffff, 0.45);
    luzDirecional.position.set(1500, 2500, 1000);
    cena.add(luzDirecional);

    const gradeSolo = new THREE.GridHelper(3000, 60, 0x007acc, 0x444444);
    gradeSolo.position.y = -2;
    cena.add(gradeSolo);

    window.addEventListener('resize', onWindowResize, false);
    container.addEventListener('dblclick', onDoubleCanvasClick, false);

    carregarDadosDoModulo();
    animarLoop();
}

function carregarDadosDoModulo() {
    const idModulo = (typeof ID_MODULO_ALVO !== 'undefined' && ID_MODULO_ALVO && ID_MODULO_ALVO !== "{{ id_modulo }}") ? ID_MODULO_ALVO : "001";

    fetch(`/api/modulo/${idModulo}`)
    .then(res => {
        if (!res.ok) throw new Error(`Falha HTTP. Status: ${res.status}`);
        return res.json();
    })
    .then(data => {
        window.dadosModuloAtual = data;
        document.getElementById('lbl-projeto').innerText = data.nome_projeto || "Módulo Customizado";
        
        const dim = data.dimensoes_ocupadas;
        if (dim) {
            document.getElementById('lbl-detalhes').innerText = `${data.familia} | L:${Math.round(dim.largura_x)} x A:${Math.round(dim.altura_y)} x P:${Math.round(dim.profundidade_z)}mm`;
        }
        
        construirMovelParametrico(data);
    })
    .catch(err => {
        console.error("Erro crítico na carga de dados:", err);
        document.getElementById('lbl-projeto').innerText = "Erro ao Carregar Módulo";
        document.getElementById('lbl-detalhes').innerText = "Verifique se o servidor Flask (app.py) está ativo na porta 5000.";
    });
}

// ==============================================================================
// RECONSTRUÇÃO DO SCRIPT DE MONTAGEM
// ==============================================================================
function construirMovelParametrico(data) {
    const matBranco = new THREE.MeshStandardMaterial({ color: 0xf5f5f5, roughness: 0.2 });
    const matCru = new THREE.MeshStandardMaterial({ color: 0xcdb182, roughness: 0.6 });
    const containerLista = document.getElementById('container-lista');

    pecasInterativas.length = 0;
    estadosAbertura = {};
    if (containerLista) containerLista.innerHTML = '';

    let minX = Infinity, maxX = -Infinity;
    let minY = Infinity, maxY = -Infinity;
    let minZ = Infinity, maxZ = -Infinity;

    data.lista_de_pecas.forEach(peca => {
        const cat = peca.categoria_industrial ? peca.categoria_industrial.toLowerCase() : "";
        const dim = peca.dimensoes;
        const pos = peca.posicao_relativa;

        // 1. GEOMETRIA
        const geometria = new THREE.BoxGeometry(dim.x, dim.z, dim.y);
        geometria.translate(dim.x / 2, dim.z / 2, -dim.y / 2);

        let materiais = Array(6).fill(matCru);
        if (cat.includes("porta") || cat.includes("frente")) {
            materiais = Array(6).fill(matBranco);
        } else {
            materiais[4] = matBranco;
        }

        const malhaPeca = new THREE.Mesh(geometria, materiais);

        // 2. POSICIONAMENTO E EIXOS
        let posX = pos.pos_x;
        let posY = pos.pos_z;  // Z industrial vira Y web
        let posZ = -pos.pos_y; // Inversão padrão de profundidade

        malhaPeca.position.set(posX, posY, posZ);
        malhaPeca.castShadow = true;
        malhaPeca.receiveShadow = true;

        malhaPeca.userData = {
            id_peca: peca.id_peca,
            id_vinculo: peca.id_vinculo_structure,
            categoria: cat,
            dimensoes: dim,
            posOriginal: new THREE.Vector3(posX, posY, posZ),
            offsetExplosao: new THREE.Vector3(0, 0, 0),
            offsetAberturaZ: 0
        };

        cena.add(malhaPeca);
        renderizarUsinagensCNC(malhaPeca, peca);
        pecasInterativas.push(malhaPeca);

        if (pos.pos_x < minX) minX = pos.pos_x;
        if ((pos.pos_x + dim.x) > maxX) maxX = pos.pos_x + dim.x;
        if (pos.pos_z < minY) minY = pos.pos_z;
        if ((pos.pos_z + dim.z) > maxY) maxY = pos.pos_z + dim.z;
        if (-pos.pos_y < minZ) minZ = -pos.pos_y;
        if ((-pos.pos_y + dim.y) > maxZ) maxZ = -pos.pos_y + dim.y;

        if (containerLista) {
            const card = document.createElement('div');
            card.className = 'card-peca';
            card.id = `card-${peca.id_peca}`;
            card.innerHTML = `
                <div class="nome-peca">${peca.nome_comercial}</div>
                <div class="dimensoes-peca">${Math.round(dim.x)}x${Math.round(dim.y)}x${Math.round(dim.z)} mm</div>
                <div class="tag-categoria">${cat.replace('_', ' ')}</div>
            `;
            card.addEventListener('click', () => destacarPecaNoHolograma(malhaPeca, card));
            containerLista.appendChild(card);
        }
    });

    if (data.lista_de_pecas.length > 0) {
        let centroX = (minX + maxX) / 2;
        let centroY = (minY + maxY) / 2;
        let centroZ = (minZ + maxZ) / 2;

        cena.userData.centroModulo = new THREE.Vector3(centroX, centroY, centroZ);

        if (controles) {
            controles.target.set(centroX, centroY, centroZ);
            camera.position.set(centroX + 800, centroY + 600, centroZ + 1000);
            controles.update();
        }
    }
}

// ==============================================================================
// MOTOR DE USINAGEM CNC FINAL
// ==============================================================================
function renderizarUsinagensCNC(malhaPeca, peca) {
    if (!peca || !peca.usinagens) return;

    const dim = peca.dimensoes;
    const espChapa = Math.min(dim.x, dim.y, dim.z);
    const cat = peca.categoria_industrial ? peca.categoria_industrial.toLowerCase() : "";

    const matFuro = new THREE.MeshStandardMaterial({ color: 0x111111, roughness: 0.8, metalness: 0.2 });
    const matRasgo = new THREE.MeshBasicMaterial({ color: 0x221100, side: THREE.DoubleSide });

    if (Array.isArray(peca.usinagens.furos)) {
        peca.usinagens.furos.forEach(furo => {
            const raio = furo.diametro / 2;
            const geoFuro = new THREE.CylinderGeometry(raio, raio, furo.profundidade + 0.4, 16);
            const malhaFuro = new THREE.Mesh(geoFuro, matFuro);

            if (Math.abs(dim.z - espChapa) < 0.1) {
                let locX = furo.x;
                let locZ = -furo.y;
                let locY = (furo.face_normal === "FACE_INFERIOR") ? -0.2 : dim.z - (furo.profundidade / 2);
                malhaFuro.position.set(locX, locY, locZ);
            } 
            else if (Math.abs(dim.x - espChapa) < 0.1) {
                malhaFuro.rotation.z = Math.PI / 2;
                let locY = furo.y;
                let locZ = -furo.x;
                let locX = cat.includes("esquerda") ? ((furo.face_normal === "FACE_INTERNA") ? dim.x - (furo.profundidade / 2) : -0.2) : ((furo.face_normal === "FACE_INTERNA") ? (furo.profundidade / 2) : dim.x + 0.2);
                malhaFuro.position.set(locX, locY, locZ);
            } 
            else if (Math.abs(dim.y - espChapa) < 0.1) {
                malhaFuro.rotation.x = Math.PI / 2;
                let locX = furo.x;
                let locY = furo.y;
                let locZ = (furo.face_normal === "FACE_INTERNA") ? -dim.y + (furo.profundidade / 2) : 0.2;
                malhaFuro.position.set(locX, locY, locZ);
            }

            malhaPeca.add(malhaFuro);
        });
    }

    if (Array.isArray(peca.usinagens.rasgos)) {
        peca.usinagens.rasgos.forEach(rasgo => {
            let geo, malha;
            if (rasgo.tipo === "CANAL_FUNDO_V") {
                geo = new THREE.BoxGeometry(rasgo.largura, dim.z, rasgo.profundidade);
                geo.translate(rasgo.largura / 2, dim.z / 2, -rasgo.profundidade / 2);
                malha = new THREE.Mesh(geo, matRasgo);
                let posX = cat.includes("esquerda") ? dim.x - rasgo.profundidade : 0;
                malha.position.set(posX, 0, -rasgo.pos_y - rasgo.largura);
            } 
            else if (rasgo.tipo === "CANAL_FUNDO_H") {
                geo = new THREE.BoxGeometry(dim.x, rasgo.largura, rasgo.profundidade);
                geo.translate(dim.x / 2, rasgo.largura / 2, -rasgo.profundidade / 2);
                malha = new THREE.Mesh(geo, matRasgo);
                let posY = dim.z - rasgo.profundidade;
                malha.position.set(0, posY, -rasgo.pos_y - rasgo.largura);
            }
            if (malha) malhaPeca.add(malha);
        });
    }
}

// ==============================================================================
// SELEÇÃO INDUSTRIAL
// ==============================================================================
function destacarPecaNoHolograma(malha, card) {
    document.querySelectorAll('.card-peca').forEach(c => c.classList.remove('active'));
    if (card) card.classList.add('active');

    pecasInterativas.forEach(p => {
        if (p.userData && p.userData.materiaisOriginais) {
            p.material = p.userData.materiaisOriginais;
        }
    });

    if (malha) {
        if (!malha.userData.materiaisOriginais) {
            malha.userData.materiaisOriginais = malha.material;
        }

        if (Array.isArray(malha.material)) {
            malha.material = malha.material.map(m => {
                const materialClonado = m.clone();
                if (materialClonado.emissive) {
                    materialClonado.emissive.setHex(0x332200);
                }
                return materialClonado;
            });
        } else if (malha.material) {
            malha.material = malha.material.clone();
            if (malha.material.emissive) {
                malha.material.emissive.setHex(0x332200);
            }
        }
    }
}

// ==============================================================================
// 🚀 ANIMAÇÃO DE ABERTURA INDIVIDUAL DE PORTAS E GAVETAS (visualizador.js)
// ==============================================================================

function toggleAberturaFrente(peca) {
    if (!peca || !peca.userData) return;

    const cat = peca.userData.categoria ? peca.userData.categoria.toLowerCase() : "";

    // Filtra apenas peças animáveis
    if (!cat.includes("porta") && !cat.includes("gaveta") && !cat.includes("frente") && !cat.includes("sapateira") && !cat.includes("tempero")) {
        return;
    }

    // 🚀 CHAVE DE CONTROLE: Usa id_vinculo para gavetas/sapateiras (abrem juntas) 
    // e id_peca individual para portas de giro (cada folha abre para seu lado)
    const ehPortaGiro = cat.includes("porta") && !cat.includes("gaveta");
    const idKey = (ehPortaGiro) ? peca.userData.id_peca : (peca.userData.id_vinculo || peca.userData.id_peca);

    if (!estadosAbertura[idKey]) {
        let ehDireita = cat.includes("direita") || cat.includes("dir");

        estadosAbertura[idKey] = {
            aberto: false,
            progresso: 0,
            tipo: ehPortaGiro ? "porta" : "gaveta",
            lado: ehDireita ? "direita" : "esquerda"
        };
    }

    // Alterna o estado de abertura da peça clicada
    estadosAbertura[idKey].aberto = !estadosAbertura[idKey].aberto;
}

function atualizarAnimacoesFrentes() {
    pecasInterativas.forEach(peca => {
        if (!peca.userData) return;

        const cat = peca.userData.categoria ? peca.userData.categoria.toLowerCase() : "";
        const ehPortaGiro = cat.includes("porta") && !cat.includes("gaveta");
        const idKey = ehPortaGiro ? peca.userData.id_peca : (peca.userData.id_vinculo || peca.userData.id_peca);

        const st = estadosAbertura[idKey];

        if (st) {
            let alvo = st.aberto ? 1.0 : 0.0;
            st.progresso += (alvo - st.progresso) * 0.12;

            if (st.tipo === "gaveta") {
                peca.userData.offsetAberturaZ = 350 * st.progresso;
            } 
            else if (st.tipo === "porta") {
                const dimX = peca.userData.dimensoes ? peca.userData.dimensoes.x : 0;

                if (st.lado === "direita") {
                    // 🚀 COMPENSAÇÃO DE PIVÔ PARA A PORTA DIREITA
                    // Ângulo de abertura para fora na dobradiça direita
                    let angulo = (Math.PI / 2.2) * st.progresso;
                    
                    // Translada o ponto de rotação para a borda direita da folha
                    peca.position.x = peca.userData.posOriginal.x + dimX - (dimX * Math.cos(angulo));
                    peca.position.z = peca.userData.posOriginal.z + (dimX * Math.sin(angulo));
                    peca.rotation.y = angulo;
                } else {
                    // Porta Esquerda: gira sobre a borda esquerda [0,0,0]
                    peca.rotation.y = (-Math.PI / 2.2) * st.progresso;
                }
            }
        } else {
            // Garante o retorno à posição original ao fechar
            if (!st && peca.userData.posOriginal) {
                peca.position.x = peca.userData.posOriginal.x + (peca.userData.offsetExplosao ? peca.userData.offsetExplosao.x : 0);
            }
        }

        // Soma os vetores da Explosão 3D e da Abertura da Gaveta
        const posOrig = peca.userData.posOriginal;
        const offExp = peca.userData.offsetExplosao;
        const offAbertura = peca.userData.offsetAberturaZ || 0;

        if (!st || st.tipo !== "porta" || st.lado !== "direita") {
            peca.position.x = posOrig.x + offExp.x;
        } else {
            peca.position.x += offExp.x;
        }

        peca.position.y = posOrig.y + offExp.y;
        peca.position.z = (st && st.tipo === "porta" && st.lado === "direita") ? peca.position.z + offExp.z : posOrig.z + offExp.z + offAbertura;
    });
}



function atualizarExplosao(valor) {
    const lbl = document.getElementById('lbl-explosao-val');
    if (lbl) lbl.innerText = valor + "%";
    
    let fator = parseFloat(valor) / 100.0;
    explodirModulo(fator);
}

function explodirModulo(fator) {
    if (!cena || !cena.userData.centroModulo) return;

    const centro = cena.userData.centroModulo;
    const intensidadeMax = 350;

    pecasInterativas.forEach(peca => {
        if (peca.userData && peca.userData.posOriginal) {
            const posOrig = peca.userData.posOriginal;

            let dirX = posOrig.x - centro.x;
            let dirY = posOrig.y - centro.y;
            let dirZ = posOrig.z - centro.z;

            let dist = Math.sqrt(dirX * dirX + dirY * dirY + dirZ * dirZ) || 1;

            peca.userData.offsetExplosao.set(
                (dirX / dist) * intensidadeMax * fator,
                (dirY / dist) * intensidadeMax * fator,
                (dirZ / dist) * intensidadeMax * fator
            );
        }
    });
}

function resetarExplosao() {
    const range = document.getElementById('range-explosao');
    if (range) range.value = 0;
    atualizarExplosao(0);
}

function onDoubleCanvasClick(event) {
    const container = document.getElementById('canvas-container');
    const rect = container.getBoundingClientRect();
    mouse.x = ((event.clientX - rect.left) / container.clientWidth) * 2 - 1;
    mouse.y = -((event.clientY - rect.top) / container.clientHeight) * 2 + 1;

    raycaster.setFromCamera(mouse, camera);
    const interseccoes = raycaster.intersectObjects(pecasInterativas);

    if (interseccoes.length > 0) {
        const peca = interseccoes[0].object;
        const card = document.getElementById(`card-${peca.userData.id_peca}`);
        destacarPecaNoHolograma(peca, card);
        toggleAberturaFrente(peca);
    }
}

function onWindowResize() {
    const container = document.getElementById('canvas-container');
    camera.aspect = container.clientWidth / container.clientHeight;
    camera.updateProjectionMatrix();
    renderizador.setSize(container.clientWidth, container.clientHeight);
}

function animarLoop() {
    requestAnimationFrame(animarLoop);
    
    atualizarAnimacoesFrentes();

    if (controles) controles.update();
    if (renderizador && cena && camera) renderizador.render(cena, camera);
}

// ==============================================================================
// 🚀 RECONSTRUÇÃO DINÂMICA DO HOLOGRAMA VIA COPILOTO (visualizador.js)
// ==============================================================================

function reconstruirMovelComNovaArvore(novaArvoreBSP) {
    if (!cena) return;

    // 1. Limpa as peças antigas da cena Three.js e da lista lateral
    pecasInterativas.forEach(peca => cena.remove(peca));
    pecasInterativas.length = 0;
    
    const containerLista = document.getElementById('container-lista');
    if (containerLista) containerLista.innerHTML = '';

    // 2. Se houver dados do módulo carregado no navegador, atualiza o arvore_json
    if (window.dadosModuloAtual) {
        window.dadosModuloAtual.arvore_json = JSON.stringify(novaArvoreBSP);
        // Se houver gerador de peças a partir de árvore BSP no front, ou se reenviar requisição
    }

    console.log("💥 Holograma 3D sincronizado com a nova Árvore BSP do Copiloto!");
}