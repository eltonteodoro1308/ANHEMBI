#INCLUDE 'TOTVS.CH'

User Function MA020ROT()

	Local aRet := {}

	aAdd( aRet, { 'Cons. CADIN'  , 'U_CADIN'  , 0, 6 } ) 
	aadd( aRet, { 'Cons. Interna', 'U_INTERNA', 0, 6 } ) 

Return aRet

User Function Cadin()

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

				DEFINE DIALOG oDlg TITLE aJsonFields[1][2][3][2] FROM oSize:aWindSize[1],oSize:aWindSize[2] TO oSize:aWindSize[3],oSize:aWindSize[4] PIXEL

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

User Function Interna()

	Local oSize       := FwDefSize():New(.T.)
	Local oDlg        := Nil
	Local cUrl        := 'http://spturis.com/v7/'

	oSize:AddObject( 'BROWSER', 000, 000, .T., .T. )

	oSize:Process()

	DEFINE DIALOG oDlg TITLE cUrl FROM oSize:aWindSize[1],oSize:aWindSize[2] TO oSize:aWindSize[3],oSize:aWindSize[4] PIXEL

	TIBrowser():New(;
	oSize:GetDimension('BROWSER','LININI'),;
	oSize:GetDimension('BROWSER','COLINI'),;
	oSize:GetDimension('BROWSER','COLEND'),;
	oSize:GetDimension('BROWSER','LINEND'),;
	cUrl,oDlg )

	EnchoiceBar( oDlg, {||Nil}, {||oDlg:End()},,,,,.F.,.F.,.F.,.F.,.F. )

	ACTIVATE DIALOG oDlg CENTERED

Return