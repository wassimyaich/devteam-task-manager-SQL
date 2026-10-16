# Étape 1 : Build de l'application
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ["DevTeamTaskManager.Api.csproj", "./"]
RUN dotnet restore "DevTeamTaskManager.Api.csproj"
COPY . .
RUN dotnet publish -c Release -o /app/publish

# Étape 2 : Exécution de l'application
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "DevTeamTaskManager.Api.dll"]