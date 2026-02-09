
    require "bundler/inline"

    gemfile do
      source "http://rubygems.org"
      gem "sinatra-contrib"
      gem "rackup"
      gem "puma"
      
      
    end
    
    require "sinatra/base"
    require "sinatra/reloader"
    require_relative "auth"
    require "securerandom"
    require "date"
    require "json"
    require "open3"       # ← Pour exécuter toilet proprement
    require "shellwords" 
class CustomAuth < Sinatra::Base

  configure :development do
   register Sinatra::Reloader
  end

    # On ne veut pas enregistrer de mot de passe en clair
    # le hachage sha256 permet d'empecher une fuite
    # des mots de passe pouvant amener a une attaque subsequente si réutilisé
    # https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html#background
   

  def authorize
    auth =  Rack::Auth::Basic::Request.new(request.env) 

    return unless auth.provided? && auth.basic? && auth.credentials

    username, password = auth.credentials 
        # auth.credentials est ["username", "password"]
        # https://docs.ruby-lang.org/en/3.1/syntax/assignment_rdoc.html#label-Array+Decomposition

    @user = username 
  end

  before do
    authorize
    # trouver l'utilisateur authentifié, s'il existe
  end
  def guard!
    auth_required = [
        401,
        { "WWW-Authenticate" => "Basic" },
        "Provide a username and password through Basic HTTP authentication"
      ]

    # HALT interrompt IMMEDIATEMENT la requête et retourne le resultat
    halt auth_required unless @user
  end

  def transform_with_toilet(text,effect)
    
    # Exécute toilet en shell, capture la sortie
     stdout, stderr, status = Open3.capture3("echo #{Shellwords.escape(text)} | toilet -F #{effect}")
    raise "Erreur toilet: #{stderr}" unless status.success?
    stdout.strip 
  end

  helpers do
    def read_recipes
      return [] unless File.exist?("files.json")
      JSON.parse(File.read("files.json"))
    end
    # Écrire les recettes dans le fichier JSON
    def write_recipes(recipes)
      File.write("files.json", recipes.to_json)
    end
  end

  get '/login' do
    guard!
    redirect '/', 303
  end

  get '/' do
    File.read('gallery.html')
  end
   
  get '/files' do
    files = read_recipes
    content_type :json 
    unless @user.nil?
      first_files = files.select { |r| r["user"] == @user }
      first_sorted_files = first_files.sort_by { |i| [ DateTime.parse(i["timestamp"]) , i["name"] ] }.reverse
      other_files = files.reject { |r| r["user"] == @user }
      other_sorted_files = other_files.sort_by { |i| [ DateTime.parse(i["timestamp"]) , i["name"] ] }.reverse
      all_files = first_sorted_files + other_sorted_files
      modified_files = all_files.map do |file|
        # Déterminer si le fichier est privé
        file['private'] = (file['password']!=nil)
        # Déterminer si le fichier appartient à l'utilisateur courant
        file['mine'] = (file['user'] == @user)
        # Supprimer les informations sensibles
        file.delete('user')
        file.delete('password')
             
        file
      end
      modified_files.to_json
    else
          
      sorted_files = files.sort_by { |i| [ DateTime.parse(i["timestamp"]) , i["name"] ] }.reverse
      modified_files = sorted_files.map do |file|
        # Déterminer si le fichier est privé
        file['private'] = (file['password']!=nil)
        # Déterminer si le fichier appartient à l'utilisateur courant
        file['mine'] = (file['user'] == @user)
        # Supprimer les informations sensibles
        file.delete('user')
        file.delete('password')
          
        file
      end
        modified_files.to_json
             
    end
  end 

  get '/files/:uuid' do
    uuid = params[:uuid]
    pass = params[:pass]
  
    file = read_recipes.find { |f| f["uuid"] == uuid }
    halt 404, "File not found" unless file
    unless @user.nil?
    #  AUTHENTIFIÉ  
    else
      if file["password"]
        # Protégé 
        halt 403, "Access denied" unless pass && pass == file["password"]
      else
        # Public 
      end
    end
    # Lecture du contenu du fichier
    filename = file["name"]
    unless File.exist?(filename)
      halt 404, "File not found on disk"
    end
    File.read(filename)
  end

  post '/files' do
    guard!
    halt 400,"error : multipart/form-data " unless request.media_type == "multipart/form-data"
    data={
      "user" => @user,
      "uuid" => SecureRandom.uuid,
      "name" => params["original_file"]["filename"],
      "timestamp" => Time.now.strftime("%Y-%m-%d %H:%M:%S"),
      "content" => params["original_file"]["tempfile"].read,
      "password" => params["password"]
    }
  
    halt 400, "manque le name" unless data["name"] && !data["name"].empty?
    halt 400 , "manque le contenu du fichier" unless data["content"] && !data["content"].empty?
    if data["password"] && data["password"].empty?
      data["password"] = nil
    end
    transformed_content = transform_with_toilet(data["content"],params["options"])
    data.delete("content")  
    base_name = File.basename(data['name'], '.*')
    ext = File.extname(data['name'])
    new_name = "#{base_name}#{ext}"
    i = 1
    while File.exist?(new_name)
      new_name = "#{base_name}#{i}#{ext}"
      i += 1
    end
    data["name"] = new_name  
    File.write(new_name, transformed_content)
    files = read_recipes
    files << data
    write_recipes(files)
    response.headers['Content-Location'] = "/files/#{data['uuid']}"
    halt 201, "c est traité"
  end
  
  patch '/files/:uuid' do
    guard!
    uuid = params[:uuid]
    new_password = request.body.read.strip  # Mot de passe direct dans body
    # Recherche fichier
    files = read_recipes
    file = files.find { |f| f["uuid"] == uuid }
    halt 404, "File not found" unless file
    # VÉRIFIE PROPRIÉTAIRE
    halt 404, "File not found" unless file["user"] == @user
    # Validation
    halt 400, "Invalid password format" unless new_password.nil? || new_password.empty? || new_password.length <= 50
    # MISE À JOUR
    if new_password.empty?
      file["password"] = nil  # Retire mot de passe
    else
      file["password"] = new_password  # Ajoute mot de passe
    end
    # Sauvegarde
    write_recipes(files)
    status 204
  end

  delete '/files/:uuid' do
    guard!
    uuid = params[:uuid]
    # Recherche fichier
    files = read_recipes
    file = files.find { |f| f["uuid"] == uuid }
    halt 404, "File not found" unless file
    # VÉRIFIE PROPRIÉTAIRE
    halt 404, "File not found" unless file["user"] == @user
    # SUPPRESSION FICHIER DISQUE
    filename = file["name"]
    if File.exist?(filename)
      File.delete(filename)
    end
    # SUPPRESSION BASE DONNÉES
    files.reject! { |f| f["uuid"] == uuid }
    write_recipes(files)
    status 204
  end

  run! if app_file == $0
end