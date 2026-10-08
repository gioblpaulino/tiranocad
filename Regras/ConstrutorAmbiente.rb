# ==============================================================================
# MOTOR DE AMBIENTAÇÃO: GERADOR DE ALVENARIA E CENÁRIOS (Regras/ConstrutorAmbiente.rb)
# ==============================================================================
class ConstrutorAmbiente
  def self.mm(val)
    return val / 25.4
  end

  def self.construir_comodo(params)
    modelo = Sketchup.active_model
    modelo.start_operation("Erguer Ambiente", true)

    begin
      entities = modelo.active_entities
      
      # Cria um grupo exclusivo para a arquitetura para não misturar com os móveis
      grp_arquitetura = entities.add_group
      grp_arquitetura.name = "AMBIENTE_ALVENARIA"

      dx = mm(params["dim_x"].to_f)
      dy = mm(params["dim_y"].to_f)
      dz = mm(params["dim_z"].to_f)
      esp = mm(params["esp_parede"].to_f)

      # 1. DESENHO DO PISO
      pts_piso = [[0, 0, 0], [dx, 0, 0], [dx, dy, 0], [0, dy, 0]]
      face_piso = grp_arquitetura.entities.add_face(pts_piso)
      face_piso.reverse! if face_piso.normal.z < 0
      
      # Pintura padrão de piso (Simulando o material do catálogo)
      mat_piso = modelo.materials["TiranoGio_Piso"] || modelo.materials.add("TiranoGio_Piso")
      mat_piso.color = [220, 220, 220] # Cinza Claro
      face_piso.material = mat_piso

      # 2. ERGUER AS PAREDES CONFORME O FORMATO EM L, U OU FECHADO
      mat_parede = modelo.materials["TiranoGio_Parede"] || modelo.materials.add("TiranoGio_Parede")
      mat_parede.color = [245, 245, 245] # Branco Off-White

      # Parede Traseira (Eixo X)
      pts_p1 = [[0, 0, 0], [dx, 0, 0], [dx, -esp, 0], [0, -esp, 0]]
      f1 = grp_arquitetura.entities.add_face(pts_p1)
      f1.reverse! if f1.normal.z < 0
      f1.pushpull(dz)

      # Parede Esquerda (Eixo Y)
      if params["formato"] == "L" || params["formato"] == "U" || params["formato"] == "FECHADO"
        pts_p2 = [[0, 0, 0], [0, dy, 0], [-esp, dy, 0], [-esp, 0, 0]]
        f2 = grp_arquitetura.entities.add_face(pts_p2)
        f2.reverse! if f2.normal.z < 0
        f2.pushpull(dz)
      end

      # Parede Direita (Fechando o 'U')
      if params["formato"] == "U" || params["formato"] == "FECHADO"
        pts_p3 = [[dx, 0, 0], [dx, dy, 0], [dx + esp, dy, 0], [dx + esp, 0, 0]]
        f3 = grp_arquitetura.entities.add_face(pts_p3)
        f3.reverse! if f3.normal.z < 0
        f3.pushpull(dz)
      end

      # Parede Frontal (Quarto Totalmente Fechado)
      if params["formato"] == "FECHADO"
        pts_p4 = [[0, dy, 0], [dx, dy, 0], [dx, dy + esp, 0], [0, dy + esp, 0]]
        f4 = grp_arquitetura.entities.add_face(pts_p4)
        f4.reverse! if f4.normal.z < 0
        f4.pushpull(dz)
      end

      # Aplica a cor em todas as faces das paredes geradas
      grp_arquitetura.entities.each do |ent|
        if ent.is_a?(Sketchup::Face) && ent != face_piso
          ent.material = mat_parede
          ent.back_material = mat_parede
        end
      end

      modelo.commit_operation
      puts "🏗️ Ambiente erguido com sucesso total!"
    rescue StandardError => e
      modelo.abort_operation
      puts "❌ Erro ao construir alvenaria: #{e.message}"
    end
  end
end