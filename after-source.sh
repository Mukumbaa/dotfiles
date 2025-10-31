rustup-init -y
go install golang.org/x/tools/gopls@latest && go install github.com/nametake/golangci-lint-langserver@latest && go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && go install golang.org/x/tools/cmd/goimports@latest && go install github.com/go-delve/delve/cmd/dlv@latest
cargo install --git https://github.com/Myriad-Dreamin/tinymist --locked tinymist-cli 
cargo install bluetui
systemctl enable iwd.service
systemctl start iwd.service
