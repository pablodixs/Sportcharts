//
//  DriverBrief.swift
//  Sportcharts
//
//  Created by Codex on 15/06/26.
//

import FoundationModels

@Generable
struct DriverBrief {
	@Guide(
		description:
			"Frase curta em português do Brasil sobre a fase atual do piloto, com no máximo 90 caracteres"
	)
	var headline: String
	
	@Guide(
		description:
			"Resumo objetivo do desempenho recente do piloto em 2 ou 3 frases, usando apenas os dados fornecidos"
	)
	var formSummary: String
	
	@Guide(
		description:
			"Até 3 pontos fortes recentes, curtos, sem inventar fatos"
	)
	var strengths: [String]
	
	@Guide(
		description:
			"Até 3 pontos de atenção recentes, curtos e construtivos, sem inventar fatos"
	)
	var watchouts: [String]
}
