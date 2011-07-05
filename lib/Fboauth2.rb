require 'rubygems'
require 'yaml'
require 'fbgraph'

module Fboauth2 
  class Newfbclient
    if Rails.env != 'production'     
     @fb_data = YAML.load_file("#{File.dirname(__FILE__)}/../config/fbconfig_test.yml")
    else
     @fb_data = YAML.load_file("#{Rails.root.to_s}/config/fbconfig.yml")
    end
    @facebook_client
    @params
    def self.get_auth(host, params)
      @params = params
      url = Newfbclient.get_url(host)
      @facebook_client =  Newfbclient.get_client #creo un nuevo cliente
      @facebook_client.authorization.authorize_url(:redirect_uri => url , :scope => @fb_data["credentials"][Rails.env]["permission"]) #pido autorizacion q me regresa una url a facebook
    end
    
    def self.get_client
      FBGraph::Client.new(:client_id => @fb_data["credentials"][Rails.env]["api_key"], :secret_id => @fb_data["credentials"][Rails.env]["api_secret"]) 
    end
    
    def self.auth_callback(code, url)
      client = @facebook_client
      client.authorization.process_callback(code, :redirect_uri => url)
      client
    end
      
    def self.get_url(host)
      @aux_params = ""
      @params.delete("controller")
      @params.delete("action")
      @params.each do |key, value|        
        @aux_params = @aux_params + key + "=" + value + "&"
      end
      "http://"+ host + "/oauth2_facebook/fb_callback?" + @aux_params #get url para el callback
    end  
    
    def self.get_conf_data
      YAML.load_file("#{RAILS_ROOT}/config/fbconfig.yml")
    end
      
    def self.crate_new_m(info, params, user)
      cname = params[:config]
      model_type = info[cname]["model"]["name"]
      m_data = info[cname]["model"]["params"]
      
      puts "-"*50
      puts "Creating #{model_type}..."
      
      m_data.each do |field, value|
        aux = value.to_s.split("_")
        if aux[0] == "fb"
          value = user["#{aux[1]}"]
          m_data[field] = value
        end  
      end
      
      if info[cname]["hsubmodel"] == "t" #si tiene algun tipo de subcategoria?
        sm_data = info[cname]["submodel"]["params"]
        sm_name = info[cname]["submodel"]["name"]
        sm_data["#{sm_name}"][0].each do |field, value|

          aux = value.to_s.split("_")
           if aux[0] == "fb"
             sm_data["#{sm_name}"][0][field] = user["#{aux[1]}"]
           end
           if aux[0] == "pm"
             sm_data["#{sm_name}"][0][field] = params[aux[1].to_sym]
           end
        end
        m_data = m_data.merge(sm_data)
      end
      
      m_aux = model_type.constantize.create(m_data)
      
      puts "-> ID: " + m_aux.id.to_s
      puts "-> Ready!"
      
      puts "-"*50
    end  
    
    
    def self.send_fb_msg(cname, user)
      @facebook_client.selection.user(user[:id]).feed.publish!(:message => @fb_data[cname]["facebook"]["message"], :name => @fb_data[cname]["facebook"]["title"], :link => @fb_data[cname]["facebook"]["link"], :picture => @fb_data[cname]["facebook"]["picture"], :description => @fb_data[cname]["facebook"]["description"])
      puts "-> Facebook Message, successfully published..."    
    end
    
    def self.get_redirect_path(params)
      url = @fb_data[params[:config]]['redirect'].split(" ")
      url_f = ""
      url.each do |value|
        aux = value.split("_")
        if aux[0] == "pm"
          url_f +=  params[aux[1].to_sym]
        else
          url_f += value
        end  
      end
      puts url_f
      return url_f
    end
      
  end  
end

