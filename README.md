# Toqua

[![Build Status](https://travis-ci.org/rogercampos/toqua.svg?branch=master)](https://travis-ci.org/rogercampos/toqua)

Collection of controller utilities for rails applications. Created with the intention of bringing back most of the nice things
about inherited resources, but in a more simple and explicit way.  

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'toqua'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install toqua

## Usage

This library contain different tools that can be used independently, described below.

### Transform params

Use this to change the value of a `params` key, for example:

```ruby
class MyController < ApplicationController
  include Toqua::TransformParams
  transform_params(:q) { |v| JSON.parse(v) }
end
```

This would transform the value of `params[:q]` from a raw string into its json representation. The new value is whatever returns your block. Also works on nested keys:

`transform_params(user: :q) {|v| DataManipulation.change(v) }`

Or more levels of nesting:

`transform_params(user: {data: :q}) {|v| DataManipulation.change(v) }`


### Scoping

This allows you to further refine an `ActiveRecord::Relation`, optionally depending on conditionals. For example:


```ruby
class MyController < ApplicationController
  include Toqua::Scoping
  
  scope {|s| s.where(parent_id: params[:parent_id])}
  
  def index
    @elements = apply_scopes(Element)
  end
end
``` 

The `scope` definitions are lambdas that receive an `ActiveRecord::Relation` as parameter and must return another
`AR::Relation`. They are chained in the order they're defined. To use them, you explicitly call `apply_scopes` with the initial
argument.

You can use `:if` or `:unless` to conditionally choose if execute the scope or not. Examples:

`scope(if: :show_all?) { |s| s.includes(:a, :b) }`

This will call the method `show_all?` defined in the controller and their return value (truthy or falsey) will indicate if the scope
applies or not. You can also use anything that responds to `:call` directly, ex:

`scope(if: -> { false }) { |s| s.all }`

Finally, you can also condition the scope execution based on the action on the controller:

`scope(only: :index) { |s| s.includes(:a, :b) }` 

This is the foundation used to build searching, sorting and pagination over an `AR::Relation`.

Used as an independent tool, it provides a way to define scopes used by multiple actions in the same place (authorization, eager loading, etc.).


### Pagination

This tool can be used to paginate collections using [Kaminari](https://github.com/kaminari/kaminari), providing some additional useful things. Example of basic usage:

```ruby
class MyController < ApplicationController
  include Toqua::Pagination
  
  paginate
  
  def index
    @elements = apply_scopes(Element)
  end
end
```

As the `paginate` method uses scoping, you can pass the options of `:if, :unless and :action` that will get forwarded to the `scope` method, allowing
you to conditionally decide when to paginate. Ex:

`paginate(only: :index)`

Or, to paginate only on html but not xlsx format:

`paginate(unless: :xlsx?)`

The names of the url parameters used to identify the current page and the number of results per page are `page` and `per_page` by default, but can be changed using:

`paginate(page_key: "page", per_page_key: "per_page")`

The number of results in each page can be controlled with the `:per` option:

`paginate(per: 100)`

The last option available is `:headers`. If used, 3 additional headers will be attached into the response allowing you to know info about the pagination of the collection. This is useful for API clients. Ex:

`paginate(headers: true)`

The response will include the following headers:

- 'X-Pagination-Total': Total number of elements in the collection without pagination
- 'X-Pagination-Per-Page': Number of elements per page
- 'X-Pagination-Page': Number of the current page

Finally, the method `paginated?` available in both the controller and the views will tell you if the collection has been paginated or not.
 

### Search

Small utility to help in the implementation of searching, using [Doure](https://github.com/rogercampos/doure) as a way to filter an AR model. Given that you have a model with filters defined, ex:

```ruby
class Post < ApplicationRecord
  extend Doure::Filterable
  filter_class PostFilter
end

class PostFilter
  cont_filter(:title)
  cont_filter(:slug)
  present_filter(:scheduled_at)
  eq_filter(:id)
  filter(:category_id_eq) { |s, value| s.joins(:post_categories).where(post_categories: {category_id: value}) }
end
```

You can setup searching in the controller using:

 
```ruby
class PostsController < ApplicationController
  include Toqua::Search
  
  searchable
  
  def index
    @elements = apply_scopes(Post)
  end
end
```

The parameter used to represent the search criteria is `:q`. 

The method `search_params` will give you a hash representing the contents of `:q`, which is the current search criteria, for example:

`{title_cont: "Air", category_id_eq: "12", slug_cont: "", scheduled_at_present: "", id_eq: ""}`

The method `active_search_params` will give you only the search parameters containing some value:

`{title_cont: "Air", category_id_eq: "12"}`

The method `search_object`, available in the view, gives an `ActiveModel` like object stuffed with the current `search_params`, so you can use that as the object 
of the search form to automatically pre-fill all the search inputs with their current value. Ex:

```slim
= form_for search_object do |f|
  = f.input :title_cont
  = f.input :category_id_eq, collection: ...
``` 

The method `searching?` will tell you if there's a current search or not.

Finally, you can define a `default_search_params` method in the controller to setup default search criteria:

```ruby
def default_search_params
  { visible_by_role: "editor" }
end
```



### Sorting

The sorting utility allows you to sort the collection, using the parameter `s` in the url with a format like `title+asc` or `title+desc`. Usage example:

```ruby
class PostsController < ApplicationController
  include Toqua::Sorting
  
  sorting
  
  def index
    @elements = apply_scopes(Post)
  end
end
```

A helper to create sorting links easily is not directly provided by the gem, but can be something like this:
 
```ruby
  def sort_link(name, label = nil, opts = {})
    label ||= name.to_s.humanize
    current_attr_name, current_direction = params[:s].present? && params[:s].split("+").map(&:strip)

    next_direction = opts.fetch(:default_order, current_direction == "asc" ? "desc" : "asc")

    parameters = request.query_parameters
    parameters.merge!(opts[:link_params]) if opts[:link_params]

    dest_url = url_for(parameters.merge(s: "#{name}+#{next_direction}"))
    direction_icon = current_direction == "asc" ? "↑" : "↓"
    anchor = current_attr_name == name.to_s ? "#{label} #{direction_icon}" : label

    link_opts = opts.fetch(:link_opts, {})

    link_to(anchor, dest_url, link_opts)
  end
```

Then used as:

`= sort_link :title, "Title"`

### Keyset pagination

The keyset pagination is similar to the pagination utility, but working with [OrderQuery](https://github.com/glebm/order_query) to provide pagination that works with no offsets. Example usage:

```ruby
class PostsController < ApplicationController
  include Toqua::KeysetPagination
  
  keyset_paginate :score_order
  
  def index
    @elements = apply_scopes(Post)
  end
end
```

It takes care of applying the correct scoping based on the id of the current element, as identified by the `:idx` parameter as default. With the optional `:headers` parameter some headers are also added into the response:

`keyset_paginate :score_order, headers: true`

Will generate those headers:

- `'X-KeysetPagination-Index'`: The `id` of the current element index.
- `'X-KeysetPagination-Next-Index'`: The `id` of the element to use as the next page.
- `'X-KeysetPagination-Prev-Index'`: The `id` of the element to use as the previous page.

The next and prev indexes are also available via the instance vars `@keyset_pagination_prev_index` and `@keyset_pagination_next_index`. 

If the value of `@keyset_pagination_prev_index` (or via header) is `-1` it means the previous page is the initial one. If it's `nil`, there's no previous page.

To generate pagination links, you can use something like this: 

```ruby
  def keyset_pagination_next_link(index_key = :idx)
    if @keyset_pagination_next_index
      url_for(request.GET.merge(index_key => @keyset_pagination_next_index))
    end
  end

  def keyset_pagination_prev_link(index_key = :idx)
    if @keyset_pagination_prev_index
      if @keyset_pagination_prev_index == -1
        url_for(request.GET.merge(index_key => nil))
      else
        url_for(request.GET.merge(index_key => @keyset_pagination_prev_index))
      end
    end
  end
```

### Final notes

If you use multiple scope declarations either mixed with the other utilities shown here or not, be aware of the order. For example, pagination must
always go last.  


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/toqua.
