# VisionClaw no iPhone, compilado sem Mac

Este ramo preserva a versão do VisionClaw que fala **diretamente com o Gemini Live** e funciona com a câmera do próprio iPhone. Ele não depende do gateway privado, LiveKit ou worker da versão atual do projeto.

## O que já está automatizado

- O GitHub Actions usa um Mac temporário hospedado pelo GitHub.
- O projeto é compilado para um iPhone físico com Xcode 16.4.
- Nenhuma chave Gemini, senha Apple ou certificado entra no repositório.
- A saída é `VisionClaw-unsigned.ipa`, pronta para o AltServer assinar localmente com sua conta Apple e instalar pelo Windows.
- O app abre usando a câmera do iPhone; os óculos Meta continuam disponíveis como opção.

## Requisitos do iPhone

- iOS 17 ou posterior.
- Modo de Desenvolvedor ativado em **Ajustes > Privacidade e Segurança > Modo de Desenvolvedor**.
- Para usar os óculos Meta, também é necessário ativar o modo de desenvolvedor no app Meta AI.

## Baixar uma compilação

1. Abra o repositório no GitHub.
2. Entre em **Actions**.
3. Abra **Build VisionClaw iOS**.
4. Escolha a execução concluída com sucesso.
5. Em **Artifacts**, baixe **VisionClaw-unsigned-ipa**.
6. Extraia o ZIP; dentro dele estará `VisionClaw-unsigned.ipa`.

O artefato fica disponível por 14 dias. Você pode iniciar outra compilação pelo botão **Run workflow** sem editar o código.

## Instalar pelo Windows sem assinatura paga

A instalação gratuita usa o AltServer. Limitações impostas pela Apple:

- o app precisa ser renovado a cada 7 dias;
- no máximo 3 apps instalados por sideload em cada aparelho;
- até 10 App IDs criados em um período de 7 dias.

### Preparação única

1. Instale o iTunes e o iCloud baixados diretamente da Apple, não as versões da Microsoft Store.
2. Instale e execute o AltServer como administrador.
3. Conecte o iPhone por USB, desbloqueie-o e aceite **Confiar neste computador**.
4. No iTunes, ative a sincronização por Wi-Fi para o iPhone.
5. No iPhone, ative o Modo de Desenvolvedor.

### Instalar diretamente o IPA

1. Mantenha a tecla **Shift** pressionada ao abrir o menu do ícone do AltServer na área de notificação do Windows.
2. Escolha **Sideload .ipa...**.
3. Selecione `VisionClaw-unsigned.ipa`.
4. Quando o AltServer solicitar credenciais, preencha-as na própria janela do AltServer. Não coloque a senha em scripts, no GitHub ou neste repositório.
5. No iPhone, se solicitado, entre em **Ajustes > Geral > VPN e Gerenciamento de Dispositivo** e confie no perfil da sua conta Apple.

O nome exato de alguns itens pode variar conforme a versão do iOS.

## Primeira execução acessível

1. Abra **VisionClaw** e conceda acesso à câmera e ao microfone.
2. O modo padrão é a câmera do iPhone.
3. Abra **Settings** pelo botão anunciado pelo VoiceOver como “Settings”.
4. No campo **API Key**, cole uma chave criada no Google AI Studio.
5. Escolha **Save**.
6. Volte à tela principal e use o botão da conversa.

A chave é salva somente nos dados locais do app (`UserDefaults`) e não entra no IPA nem no GitHub. Se o app for removido, essa configuração poderá ser perdida.

## Compilar manualmente no GitHub

O workflow fica em `.github/workflows/build-ios.yml`. Ele cria somente um IPA **sem assinatura**. A assinatura acontece no Windows pelo AltServer, vinculada à sua conta e ao seu iPhone.

Para ver o estado pelo terminal:

```bash
gh run list --workflow build-ios.yml --branch ios-direct-gemini
gh run view RUN_ID --log-failed
gh run download RUN_ID -n VisionClaw-unsigned-ipa
```

## Alternativa sem renovação semanal

O Apple Developer Program custa US$ 99 por ano. Com a assinatura paga, podemos acrescentar um segundo workflow para TestFlight ou para um IPA assinado. Isso exige certificados/provisionamento ou uma chave do App Store Connect guardados como GitHub Secrets. Não é necessário para o primeiro teste gratuito.

## Segurança

- Não grave a chave Gemini em `Secrets.swift` antes de enviar alterações ao GitHub.
- `CameraAccess/Secrets.swift` está ignorado pelo Git.
- Nunca salve senha da conta Apple em GitHub Secrets; o AltServer solicita essa credencial localmente.
- O workflow usa apenas valores de exemplo para provar que todo o app compila sem segredos.

## Fontes primárias

- Apple, comparação de associações e limites da conta gratuita: https://developer.apple.com/support/compare-memberships
- GitHub, assinatura de apps Xcode em runners macOS: https://docs.github.com/en/actions/deployment/deploying-xcode-applications
- AltStore, instalação no Windows: https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows
- AltStore, limites e renovação dos apps: https://faq.altstore.io/altstore-classic/your-altstore
