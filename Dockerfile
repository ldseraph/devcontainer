FROM ubuntu:latest

ENV GOLANG_VERSION 1.19.5
ENV PATH /usr/local/go/bin:$PATH

RUN apt update; \
		apt install -y --no-install-recommends ca-certificates wget

RUN echo "deb [signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian/ stable main" | tee /etc/apt/sources.list.d/azlux.list; \
		wget -O /usr/share/keyrings/azlux-archive-keyring.gpg  https://azlux.fr/repo.gpg

RUN set -eux; \
	apt update; \
	apt install -y --no-install-recommends \
		g++ \
		gcc \
		libc6-dev \
		make \
		pkg-config \
		git \
		zsh \
		fzf \
		exa \
		broot \
		btop \
		bat \
	; \
	rm -rf /var/lib/apt/lists/*

RUN set -eux; \
  url="https://dl.google.com/go/go$GOLANG_VERSION.linux-amd64.tar.gz"; \
	wget -O go.tgz "$url" --progress=dot:giga; \
	tar -C /usr/local -xzf go.tgz; \
	rm go.tgz; \
	go version

ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

RUN go install github.com/cosmtrek/air@latest; \
	go install golang.org/x/lint/golint@latest; \
	go install github.com/axw/gocov/gocov@latest; \
	go install github.com/AlekSi/gocov-xml@latest; \
	go install github.com/tebeka/go2xunit@latest; \
	go install github.com/mitchellh/gox@latest; \
	go install github.com/swaggo/swag/cmd/swag@latest

RUN curl https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh -s -- --unattended
RUN chsh --shell /bin/zsh root
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
RUN git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
RUN git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
COPY .zshrc ./

RUN wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
# RUN nvm install node
# RUN corepack enable

ENV MIRRORS "http://mirrors.tuna.tsinghua.edu.cn"
    # MIRRORS="http://mirrors.aliyun.com"

RUN sed -i "s@http://.*archive.ubuntu.com@$MIRRORS@g" /etc/apt/sources.list; \
    sed -i "s@http://.*security.ubuntu.com@$MIRRORS@g" /etc/apt/sources.list


