class WelcomeController < ApplicationController
  def index
    @nof_refs = Reference.count
  end
end
