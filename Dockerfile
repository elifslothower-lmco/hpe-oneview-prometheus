# Build stage
FROM golang:1.25 AS builder

WORKDIR /build

# Ensure Go fetches modules directly and skips checksum DB
ENV GOPROXY=direct
ENV GOSUMDB=off
ENV GOINSECURE=golang.org,google.golang.org,gopkg.in,go.uber.org,go.yaml.in

# Install CA certificates and git
RUN apt-get update && \
    apt-get install -y ca-certificates git && \
    update-ca-certificates

# (Optional) disable Git SSL verification if your proxy requires it
RUN git config --global http.sslVerify false

# Copy module files first (so dependency downloads are cached)
COPY go.mod go.sum ./

# Copy source code
COPY hpe-oneview-exporter.go ./

# Resolve dependencies
RUN go mod tidy

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux go build -v -a -tags "static-netgo" \
    -ldflags '-w' -o hpe-oneview-exporter hpe-oneview-exporter.go

# Final stage: minimal image
FROM scratch
COPY --from=builder /build/hpe-oneview-exporter /app/hpe-oneview-exporter
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["/app/hpe-oneview-exporter"]

