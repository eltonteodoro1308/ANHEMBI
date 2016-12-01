#INCLUDE 'TOTVS.CH'
#DEFINE cEnter Chr(13) + Chr(10)

/*/{Protheus.doc} MA020ROT
//Ponto de Entrada que inclui rotina no aRotina do cadastro de Fornecerdores (MATA020)
@author Elton Teodoro Alves
@since 01/12/2016
@version 12.1.007 
@return Array, Array com as definições das rotinas a serem incluidas 
/*/
User Function MA020ROT()

	Local aRet := {}

	aAdd( aRet, { 'Consulta CADIN'  ,;
	 'MsgRun( CapitalAce("Consulta Solicitada, Aguardando Resposta..."), CapitalAce("Atenção !!!"), { || U_CNSCADIN() } )'  , 0, 6 } ) 

	aadd( aRet, { 'Consulta TST',;
	'U_CNSSITE( "http://www.tst.jus.br/certidao/" )', 0, 6 } ) 

	aadd( aRet, { 'Consulta PGFN',;
	 'U_CNSSITE( "http://www.receita.fazenda.gov.br/Aplicacoes/ATSPO/Certidao/CndConjuntaInter/InformaNICertidao.asp?tipo=1" )', 0, 6 } ) 

	aadd( aRet, { 'Consulta FGTS',;
	 'U_CNSSITE( "https://www.sifge.caixa.gov.br/Cidadao/Crf/FgeCfSCriteriosPesquisa.asp" )', 0, 6 } ) 

	aadd( aRet, { 'Consulta CNPJ',;
	 'U_CNSSITE( "http://www.receita.fazenda.gov.br/pessoajuridica/cnpj/cnpjreva/cnpjreva_solicitacao.asp" )', 0, 6 } ) 

	aadd( aRet, { 'Consulta CADIN Municipal',;
	 'U_CNSSITE( "http://www3.prefeitura.sp.gov.br/cadin/Pesq_Deb.aspx" )', 0, 6 } ) 

Return aRet

/*/{Protheus.doc} CnsCadin
//User Function que executa a consulta na API do CADIN da situação de fornecedor e grava o LOG 
@author Elton Teodoro Alves
@since 01/12/2016
@version 12.1.007
/*/
User Function CnsCadin()

	Local oJson       := TJsonParser():New()
	Local cUrl        := 'http://sfmobile.prefeitura.sp.gov.br/api/Cadin/GetDebitosCadin?'
	Local cTipo       := ''
	Local cCnpj       := ''
	Local cJson       := ''
	Local aJsonFields := {}
	Local nRetParser  := 0
	Local oSize       := FwDefSize():New(.T.)
	Local oDlg        := Nil
	Local oList       := Nil
	Local aList       := {}
	Local nX          := 0
	Local cNumPend    := ''
	Local cOrgao      := '' 
	Local cData       := ''

	If SA2->A2_TIPO == 'F'

		cTipo := 'cpf'

	ElseIf SA2->A2_TIPO == 'J'

		cTipo := 'cnpj'

	Else

		ApMsgStop( 'Rotina válida apenas para fornecedores do Tipo Físico ou Jurídico.', 'Atenção !!!' )

		Return

	End If

	If EmPty( SA2->A2_CGC )

		ApMsgStop( 'CNPJ ou CPF não preenchido.', 'Atenção !!!' )

		Return

	End If

	cUrl += 'tipoDocumento=' + cTipo + '&'
	cUrl += 'numDocumento=' + SA2->A2_CGC

	cJson :=  DecodeUTF8( HttpGet( cUrl ) )

	If ! oJson:Json_Parser( cJson, Len( cJson ), @aJsonFields, @nRetParser )

		ApMsgStop( 'Problemas no retorno da Consulta.', 'Atenção !!!' )

	Else

		RecLock( 'SA2', .F. )

		cData += PadL( cValToChar( Day( Date() ) ), 2, '0' ) + '/'
		cData += PadL( cValToChar( Month( Date() ) ), 2, '0' ) + '/'
		cData += cValToChar( Year( Date() ) )

		SA2->A2_XSITLOG := 'CADIN: ' + If( aJsonFields[1][2][1][2] != 0, 'Sem Pendências', 'Com Pendências' ) + cEnter +;
		'Usuário: ' + SubStr( cUsuario, 7, 15 ) + cEnter +;
		'Data/Hora: ' + cData + ' - ' + Time()  + cEnter +;
		Padc('',35,'-')  + cEnter +;
		SA2->A2_XSITLOG

		MsUnlock()

		If aJsonFields[1][2][1][2] != 0

			ApMsgInfo( 'Não há Pendencias registradas no CADIN.', 'Atenção !!!' )

		Else

			If ApMsgYesNo( 'Há Pendencias registradas no CADIN, deseja exibir ?', 'Atenção !!!' )

				For nX := 1 To Len( aJsonFields[1][2][4][2] )

					cOrgao   := aJsonFields[1][2][4][2][nX][2][1][2]
					cNumPend := aJsonFields[1][2][4][2][nX][2][2][2]

					aAdd( aList, { cNumPend, cOrgao } )

				Next nX

				oSize:AddObject( "LISTA", 000, 000, .T., .T. )

				oSize:Process()

				DEFINE DIALOG oDlg TITLE aJsonFields[1][2][3][2] FROM;
				oSize:aWindSize[1],oSize:aWindSize[2] TO oSize:aWindSize[3],oSize:aWindSize[4] PIXEL

				@oSize:GetDimension("LISTA","LININI"), oSize:GetDimension("LISTA","COLINI");
				LISTBOX oList Fields HEADER '';
				SIZE oSize:GetDimension("LISTA","COLEND"), oSize:GetDimension("LISTA","LINEND") OF oDlg PIXEL

				oList:aHeaders := { 'Número de Pendências', 'Orgão Responsável' }

				oList:SetArray( aList )

				oList:bLine := {|| {;
				aList[oList:nAt,1],;
				aList[oList:nAt,2];
				}}

				EnchoiceBar( oDlg, {||Nil}, {||oDlg:End()},,,,,.F.,.F.,.F.,.F.,.F. )

				ACTIVATE DIALOG oDlg CENTERED

			End If

		End If

	End If

Return

/*/{Protheus.doc} CnsSite
//Exibe portal da URL enviada por parêmetro
@author Elton Teodoro Alves
@since 01/12/2016
@version 12.1.007
@param cUrl, Caracter, URL do portal a ser carregado no Browser
/*/
User Function CnsSite( cUrl )

	Local oSize       := FwDefSize():New(.T.)
	Local oDlg        := Nil
	Local oTiBrowser  := Nil

	oSize:AddObject( 'BROWSER', 000, 000, .T., .T. )

	oSize:Process()

	DEFINE DIALOG oDlg TITLE cUrl FROM;
	oSize:aWindSize[1],oSize:aWindSize[2] TO oSize:aWindSize[3],oSize:aWindSize[4] PIXEL

	oTiBrowser := TIBrowser():New(;
	oSize:GetDimension('BROWSER','LININI'),;
	oSize:GetDimension('BROWSER','COLINI'),;
	oSize:GetDimension('BROWSER','COLEND'),;
	oSize:GetDimension('BROWSER','LINEND'),;
	cUrl,oDlg )

	EnchoiceBar( oDlg, {||Nil}, {||oDlg:End()},,{ {'',{|| oTiBrowser:Navigate( cURL ) },;
	'Abrir a Página Inicial'}, {'',{|| oTiBrowser:Print()},'Imprimir' } };
	,,,.F.,.F.,.T.,.F.,.F. )

	ACTIVATE DIALOG oDlg CENTERED

Return