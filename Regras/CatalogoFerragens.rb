# ==============================================================================
# BANCO DE DADOS: CATÁLOGO DE FERRAGENS (Regras/CatalogoFerragens.rb)
# ==============================================================================

module CatalogoFerragens
  def self.obter
    {
      fixadores: {
        parafuso_5x50: { diametro_passante: 5.0, diametro_topo: 5.0, profundidade_topo: 25.0 },
        parafuso_4x40: { diametro: 4.5 }, # Furo para gavetas e temperos
        pino_prateleira: { diametro: 5.0, profundidade: 10.0 },
        
        # O Combo de Alta Marcenaria
        minifix_15mm: { diametro_pino: 5.0, prof_pino: 12.0, diametro_caneco: 15.0, prof_caneco: 13.0, recuo_caneco: 34.0 },
        cavilha_8x30: { diametro: 8.0, prof_face: 12.0 },
        
        regras_posicionamento: { distancia_frontal: 35.0, distancia_traseira: 35.0, distancia_cavilha: 32.0 }
      },
      dobradicas: {
        reta_35mm: {
          diametro_caneco: 35.0, profundidade_caneco: 11.5, posicao_caneco: 22.5,
          distancia_furos_calco: 32.0, afastamento_calco_borda: 37.0,
          z_inferior: 100.0, z_superior: 100.0,
          diametro_picote: 3.0, profundidade_picote: 1.0, 
          afastamento_picote_caneco: 9.5, distancia_picotes: 48.0 
        }
      },
      corredicas: {
        telescopica: {
          "300mm" => { furos_y: [37.0, 165.0, 261.0], diametro_furo: 3.0, profundidade_furo: 1.0 },
          "350mm" => { furos_y: [37.0, 165.0, 293.0], diametro_furo: 3.0, profundidade_furo: 1.0 },
          "400mm" => { furos_y: [37.0, 165.0, 357.0], diametro_furo: 3.0, profundidade_furo: 1.0 },
          "450mm" => { furos_y: [37.0, 165.0, 389.0], diametro_furo: 3.0, profundidade_furo: 1.0 },
          "500mm" => { furos_y: [37.0, 165.0, 421.0], diametro_furo: 3.0, profundidade_furo: 1.0 }
        }
      }
    }
  end
end