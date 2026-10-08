# ==============================================================================
# MOTOR DE VISUALIZAÇÃO: RENDERIZADOR 3D SEGURO V3 (Sketchup/Renderizador.rb)
# Industrialização CNC Assegurada e Alinhamento Cinemático Paramétrico
# ==============================================================================
require 'sketchup.rb'
require_relative '../Regras/RenderizadorMateriais'
require_relative '../Regras/OrquestradorUsinagens' 

class Renderizador
  # Conversor estrito de Milímetros para Polegadas (Padrão Interno SketchUp)
  def self.mm(valor) 
    return valor / 25.4 
  end

  def self.desenhar_modulo(modulo_obj, transformacao_antiga = nil, params = {})
    modelo = Sketchup.active_model
    modelo.start_operation("Gerar #{modulo_obj.nome_amigavel}", true)

    begin
      # 1. DISPARO E SINCRO DO RADAR DE USINAGENS CNC
      if defined?(OrquestradorUsinagens)
        OrquestradorUsinagens.processar(modulo_obj)
      end

      # Assegura a existência do material de marcação para furos e canecos
      mat_furo = modelo.materials["TiranoGio_Furo"] || modelo.materials.add("TiranoGio_Furo")
      mat_furo.color = "Black" if mat_furo.respond_to?(:color=)

      # 2. CÁLCULO DE ACÚMULO AUTOMÁTICO DE MÓDULOS NO EIXO X
      maior_x = 0.0
      modelo.entities.each do |ent|
        if ent.is_a?(Sketchup::Group) && ent.get_attribute("TiranoGio", "is_modulo")
          max_x = ent.bounds.max.x
          maior_x = max_x if max_x > maior_x
        end
      end

      # 3. CRIAÇÃO DO CONTÊNER PRINCIPAL DO MÓDULO E METADADOS INDUSTRIAIS
      grp_modulo = modelo.active_entities.add_group
      grp_modulo.name = modulo_obj.id_modulo
      grp_modulo.set_attribute("TiranoGio", "is_modulo", true)
      grp_modulo.set_attribute("TiranoGio", "id_original", modulo_obj.id_modulo)
      grp_modulo.set_attribute("TiranoGio", "guid", modulo_obj.guid_universal)
      grp_modulo.set_attribute("TiranoGio", "w", modulo_obj.dimensoes_totais[:largura_x])
      grp_modulo.set_attribute("TiranoGio", "h", modulo_obj.dimensoes_totais[:altura_y])
      grp_modulo.set_attribute("TiranoGio", "d", modulo_obj.dimensoes_totais[:profundidade_z])
          
      # 🚀 PERSISTÊNCIA DO DNA PARA REEDIÇÃO INTEGRA
      if params["arvore_json"] && !params["arvore_json"].empty?
        grp_modulo.set_attribute("TiranoGio", "arvore_json", params["arvore_json"])
      end
      grp_modulo.set_attribute("TiranoGio", "categoria_modulo", params["categoria_modulo"] || "INFERIOR")
      grp_modulo.set_attribute("TiranoGio", "perfil_montagem", params["perfil_montagem"] || "Padrao_Gemini")
      grp_modulo.set_attribute("TiranoGio", "material_caixaria", params["material_caixaria"] || "generico_branco_tx")
      grp_modulo.set_attribute("TiranoGio", "material_frentes", params["material_frentes"] || "arauco_louro_freijo")
      grp_modulo.set_attribute("TiranoGio", "montagem_caixa", params["montagem_caixa"] || "Base Passante")
      grp_modulo.set_attribute("TiranoGio", "tipo_sarrafo_tras", params["tipo_sarrafo_tras"] || "deitado")
      grp_modulo.set_attribute("TiranoGio", "com_fundo", params["com_fundo"] ? true : false)

      gavetas_subgrupos = {} 

      # 4. MATERIALIZAÇÃO GEOMÉTRICA DAS CHAPAS DE MDF
      modulo_obj.pecas.each do |peca|
        begin
          categoria = peca.categoria_industrial
          categoria_str = categoria.to_s.upcase
          parente = grp_modulo

          px = peca.posicao_relativa[:pos_x]
          py = peca.posicao_relativa[:pos_y]
          pz = peca.posicao_relativa[:pos_z]
          dx = peca.dimensoes[:x]
          dy = peca.dimensoes[:y]
          dz = peca.dimensoes[:z]

          # Agrupamento inteligente via UUID de Vínculo Estrutural (Gavetas e Temperos)
          if peca.respond_to?(:id_vinculo_structure) && !peca.id_vinculo_structure.nil?
            componentes_caixote = [
              :lateral_gaveta, :lateral_gaveta_esquerda, :lateral_gaveta_direita, :ctrf_gaveta, :traseira_gaveta, :fundo_gaveta,
              :base_porta_tempero, :traseira_porta_tempero, :contra_frente_tempero,
              :prateleira_interno_tempero, :frente_gaveta, :frente_gavetaao, :frente_porta_tempero, 
              :frente_sapateira, :frente_gaveta_interna,  :frente_sapateira_interna, 
              :traseira_sapateira_interna, :base_sapateira_interna
            ]
            if componentes_caixote.include?(categoria) || categoria.to_s.include?("haste_protecao")
              gav_id = peca.id_vinculo_structure
              unless gavetas_subgrupos[gav_id]
                gav_grp = grp_modulo.entities.add_group
                gav_grp.name = "CAIXOTE_#{peca.nome_comercial}"
                
                prof_movel = modulo_obj.dimensoes_totais[:profundidade_z]
                abertura = prof_movel - 50.0
                gav_grp.set_attribute("dynamic_attributes", "onclick", "ANIMATE(\"Y\", 0, -#{mm(abertura)})")
                
                gavetas_subgrupos[gav_id] = gav_grp
              end
              parente = gavetas_subgrupos[gav_id]
            end
          end

          is_right = (categoria == :porta_giro_direita)
          is_left = (categoria == :porta_giro_esquerda)
                  
          # 🚀 SOLUÇÃO PONTO 3: Compensação cinemática de eixos para frentes recuadas
          if is_right
            pivot = parente.entities.add_group
            pivot.name = "PIVOT_DIR_#{peca.nome_comercial}"
            
            # Reposiciona o pivô considerando a espessura da frente externa para evitar colisões
            pivot.transform!(Geom::Transformation.translation([mm(px + dx), mm(py), mm(pz)]))
            pivot.set_attribute("dynamic_attributes", "onclick", "ANIMATE(\"RotZ\", 0, 90)")
            
            grp_peca = pivot.entities.add_group
            movimento = Geom::Transformation.translation([-mm(dx), 0, 0])
            
          elsif is_left
            pivot = parente.entities.add_group
            pivot.name = "PIVOT_ESQ_#{peca.nome_comercial}"
            
            # O ponto zero do PIVOT_ESQ absorve o vetor de rotação rente à face externa
            pivot.transform!(Geom::Transformation.translation([mm(px), mm(py), mm(pz)]))
            pivot.set_attribute("dynamic_attributes", "onclick", "ANIMATE(\"RotZ\", 0, -90)")
            
            grp_peca = pivot.entities.add_group
            movimento = Geom::Transformation.new
            
          else
            grp_peca = parente.entities.add_group
            RenderizadorMateriais.aplicar(grp_peca, peca)
            movimento = Geom::Transformation.translation([mm(px), mm(py), mm(pz)])
          end

          grp_peca.name = peca.nome_comercial
          grp_peca.set_attribute("TiranoGio", "papel_estrutural", categoria_str)
          grp_peca.set_attribute("TiranoGio", "categoria_industrial", categoria.to_s)

          # Geração da geometria primitiva da chapa
          pts = [ [0,0,0], [mm(dx),0,0], [mm(dx),mm(dy),0], [0,mm(dy),0] ]
          face_base = grp_peca.entities.add_face(pts)
          face_base.reverse! if face_base.normal.z < 0
          face_base.pushpull(mm(dz))

          # Pintura de faces de topo baseado em fita de borda
          RenderizadorMateriais.aplicar(grp_peca, peca) if defined?(RenderizadorMateriais)
          grp_peca.transform!(movimento)

          # ========================================================================
          # 🚀 SEÇÃO 5: INDUSTRIALIZAÇÃO CNC - PERFURAÇÃO REAL DE BROCAS NO MDF
          # ========================================================================
          esp_chapa = [dx, dy, dz].min 
          
          if peca.usinagens && peca.usinagens[:furos]
            peca.usinagens[:furos].each do |furo|
              begin
                fx = furo[:x]; fy = furo[:y]
                diametro = furo[:diametro]; profundidade = furo[:profundidade]
                
                px_local, py_local, pz_local = 0.0, 0.0, 0.0
                vetor_furo = Geom::Vector3d.new(0,0,1) 

                # Identificação de planos tridimensionais das faces
                if (dz - esp_chapa).abs < 0.1 # Peças horizontais (Bases/Prateleiras)
                  px_local = mm(fx); py_local = mm(fy)
                  pz_local = (furo[:face_normal] == "FACE_INFERIOR") ? 0.0 : mm(dz)
                  vetor_furo = (furo[:face_normal] == "FACE_INFERIOR") ? Geom::Vector3d.new(0,0,-1) : Geom::Vector3d.new(0,0,1)
                elsif (dx - esp_chapa).abs < 0.1 # Peças em pé laterais (Laterais/Divisórias)
                  px_local = (furo[:face_normal] == "FACE_INTERNA") ? (categoria_str.include?("DIREITA") ? 0.0 : mm(dx)) : (categoria_str.include?("DIREITA") ? mm(dx) : 0.0)
                  vetor_furo = (furo[:face_normal] == "FACE_INTERNA") ? (categoria_str.include?("DIREITA") ? Geom::Vector3d.new(1,0,0) : Geom::Vector3d.new(-1,0,0)) : (categoria_str.include?("DIREITA") ? Geom::Vector3d.new(-1,0,0) : Geom::Vector3d.new(1,0,0))
                  py_local = mm(fx); pz_local = mm(fy)
                elsif (dy - esp_chapa).abs < 0.1 # Peças frontais/traseiras (Frentes/Contra-frentes)
                  px_local = mm(fx); pz_local = mm(fy)
                  py_local = (furo[:face_normal] == "FACE_INTERNA") ? mm(dy) : 0.0
                  vetor_furo = (furo[:face_normal] == "FACE_INTERNA") ? Geom::Vector3d.new(0,1,0) : Geom::Vector3d.new(0,-1,0)
                end

                ponto_furo = Geom::Point3d.new(px_local, py_local, pz_local)
                circulo = grp_peca.entities.add_circle(ponto_furo, vetor_furo, mm(diametro / 2.0))
                face_furo_gerada = circulo[0].faces[0]

                if face_furo_gerada
                  face_furo_gerada.material = mat_furo
                  face_furo_gerada.back_material = mat_furo
                  face_furo_gerada.pushpull(-mm(profundidade))
                end
              rescue StandardError => e_furo
                puts "Erro ao perfurar chapa CNC: #{e_furo.message}"
              end
            end
          end

          # ========================================================================
          # 🚀 SEÇÃO 5B: EXTRUSÃO GEOMÉTRICA DE CANAIS DE FUNDO E GAVETA
          # ========================================================================
          if peca.usinagens && peca.usinagens[:rasgos]
            peca.usinagens[:rasgos].each do |rasgo|
              begin
                larg = rasgo[:largura]
                prof = rasgo[:profundidade]
                pts_corta = nil

                if rasgo[:tipo] == "CANAL_FUNDO_V"
                  y_ras = rasgo[:pos_y]
                  x_c = (categoria == :lateral_direita) ? 0.0 : mm(dx)
                  pts_corta = [
                    Geom::Point3d.new(x_c, mm(y_ras), 0),
                    Geom::Point3d.new(x_c, mm(y_ras + larg), 0),
                    Geom::Point3d.new(x_c, mm(y_ras + larg), mm(dz)),
                    Geom::Point3d.new(x_c, mm(y_ras), mm(dz))
                  ]
                elsif rasgo[:tipo] == "CANAL_FUNDO_H"
                  y_ras = rasgo[:pos_y]
                  z_c = (categoria == :base_superior) ? 0.0 : mm(dz)
                  pts_corta = [
                    Geom::Point3d.new(0, mm(y_ras), z_c),
                    Geom::Point3d.new(mm(dx), mm(y_ras), z_c),
                    Geom::Point3d.new(mm(dx), mm(y_ras + larg), z_c),
                    Geom::Point3d.new(0, mm(y_ras + larg), z_c)
                  ]
                elsif rasgo[:tipo] == "CANAL_GAVETA_Y"
                  z_ras = rasgo[:pos_z_local]
                  is_direita = peca.categoria_industrial == :lateral_gaveta_direita || peca.nome_comercial.include?("Dir.")
                  x_c = is_direita ? 0.0 : mm(dx)
                  pts_corta = [
                    Geom::Point3d.new(x_c, 0, mm(z_ras)),
                    Geom::Point3d.new(x_c, mm(dy), mm(z_ras)),
                    Geom::Point3d.new(x_c, mm(dy), mm(z_ras + larg)),
                    Geom::Point3d.new(x_c, 0, mm(z_ras + larg))
                  ]
                elsif rasgo[:tipo] == "CANAL_GAVETA_X"
                  z_ras = rasgo[:pos_z_local]
                  y_c = (categoria == :traseira_gaveta || categoria == :traseira_porta_tempero) ? 0.0 : mm(dy)
                  pts_corta = [
                    Geom::Point3d.new(0, y_c, mm(z_ras)),
                    Geom::Point3d.new(mm(dx), y_c, mm(z_ras)),
                    Geom::Point3d.new(mm(dx), y_c, mm(z_ras + larg)),
                    Geom::Point3d.new(0, y_c, mm(z_ras + larg))
                  ]
                end

                if pts_corta
                  volume_antes = grp_peca.volume rescue 0.0
                  f_canal = grp_peca.entities.add_face(pts_corta)
                  f_canal.material = mat_furo
                  f_canal.back_material = mat_furo
                  
                  f_canal.pushpull(-mm(prof))
                  volume_depois = grp_peca.volume rescue 0.0

                  if volume_depois >= volume_antes && volume_antes > 0
                    f_canal.pushpull(mm(prof * 2)) rescue nil
                  end
                end
              rescue StandardError => e_rasgo
                puts "Erro ao fresar canal de fundo CNC: #{e_rasgo.message}"
              end
            end
          end

        rescue StandardError => e_peca
          puts "Erro ao materializar peca #{peca.nome_comercial}: #{e_peca.message}"
        end
      end

      # 5. POSICIONAMENTO FINAL ABSOLUTO DO MÓDULO NO ESPAÇO CAD
      px_amb = params["ambiente_pos_x"] ? mm(params["ambiente_pos_x"].to_f) : 0.0
      py_amb = params["ambiente_pos_y"] ? mm(params["ambiente_pos_y"].to_f) : 0.0
      pz_amb = params["ambiente_pos_z"] ? mm(params["ambiente_pos_z"].to_f) : 0.0
      rot_amb = params["ambiente_rot_z"] ? params["ambiente_rot_z"].to_f : 0.0

      if px_amb == 0.0 && py_amb == 0.0 && pz_amb == 0.0
        deslocamento = Geom::Transformation.translation([maior_x + mm(20.0), 0, 0])
      else
        trans_absoluta = Geom::Transformation.translation([px_amb, py_amb, pz_amb])
        rot_absolute = Geom::Transformation.rotation([px_amb, py_amb, pz_amb], [0, 0, 1], rot_amb.degrees)
        deslocamento = trans_absoluta * rot_absolute
      end

      if transformacao_antiga
        grp_modulo.transform!(transformacao_antiga)
      else
        grp_modulo.transform!(deslocamento)
      end

      modelo.commit_operation
      puts "🎉 Módulo #{modulo_obj.id_modulo} integrado ao ambiente com sucesso!"
    rescue StandardError => e
      modelo.abort_operation
      puts "❌ Falha crítica no Renderizador: #{e.message}"
    end
  end
end