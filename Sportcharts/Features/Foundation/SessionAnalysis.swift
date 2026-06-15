//
//  SessionAnalysisViewModel.swift
//  Sportcharts
//
//  Created by Pablo Dias on 28/05/26.
//

import FoundationModels

@Generable
struct SessionAnalysis {
	@Guide(
		description:
			"Resumo da sessão em português do Brasil, objetivo, entre 2 e 4 frases"
	)
	var summary: String
	
	@Guide(
		description:
			"Pontos positivos da sessão em tópicos curtos, sem repetir informação"
	)
	var positives: [String]
	
	@Guide(
		description:
			"Pontos que precisam melhorar em tópicos curtos, com linguagem construtiva"
	)
	var improvements: [String]
	
	@Guide(
		description:
			"Próxima ação recomendada em uma frase direta e acionável"
	)
	var nextAction: String
	
	@Guide(
		description:
			"Números dos carros dos pilotos citados na análise. Use apenas números presentes no contexto, sem duplicidade"
	)
	var driverNumbers: [Int]
}
