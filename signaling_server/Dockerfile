# Stage 1: Build
FROM dart:stable AS build

WORKDIR /app

# Copy pubspec and get dependencies first (better layer caching)
COPY pubspec.* ./
RUN dart pub get

# Copy source and compile
COPY . .
RUN dart compile exe bin/server.dart -o bin/server

# Stage 2: Minimal runtime image
FROM scratch

COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

EXPOSE 8080

CMD ["/app/bin/server"]
