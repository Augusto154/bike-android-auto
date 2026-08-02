# AndroidBike

Painel Flutter para usar o celular na bicicleta: velocímetro por GPS, mapa, painel de entregas, atalhos para música, chamadas e mensagens, além de configurações.

## Executar

1. Instale o [Flutter](https://docs.flutter.dev/get-started/install) com suporte a Android.
2. Na pasta do projeto, execute `flutter pub get`.
3. Caso esta seja a primeira vez que for abrir o projeto nesta máquina, execute `flutter create .` para adicionar os arquivos nativos Android/iOS/Web.
4. Conecte um celular Android e execute `flutter run`.

O módulo **Entregas** abre `https://entrega.roggia.com.br/entregador.php` dentro do próprio aplicativo. O app pede a permissão de localização ao abrir, usada pelo velocímetro e pelo mapa.

## Próximos incrementos

- Salvar distância e histórico de trajetos.
- Exibir navegação curva a curva.
- Integrar controles da sessão de música do Android.
- Receber e anunciar novos pedidos.
