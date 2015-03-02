class StaticPagesController < ApplicationController
  def about
    render "about"
  end

  def examples
    render "examples"
  end

  def how_it_works
    render "how_it_works"
  end
end
