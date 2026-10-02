interface ProductImageProps {
  src: string | null;
  alt: string;
  className?: string;
}

export function ProductImage({ src, alt, className = '' }: ProductImageProps) {
  return (
    <div className={`overflow-hidden rounded-xl bg-primary-tint/50 ${className}`}>
      {src ? (
        // Las URLs las cargan administradores desde cualquier dominio; next/image
        // obligaría a declarar cada dominio en next.config.
        // eslint-disable-next-line @next/next/no-img-element
        <img src={src} alt={alt} loading="lazy" className="h-full w-full object-cover" />
      ) : (
        <div aria-hidden className="flex h-full w-full items-center justify-center">
          {/* Producto sin foto: una bolsa de compras en el tono de la marca. */}
          <svg
            viewBox="0 0 24 24"
            focusable="false"
            className="h-1/4 w-1/4 fill-none stroke-primary-dark/40 stroke-[1.5]"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M5 8h14l-1 12H6L5 8Z" />
            <path d="M9 10V7a3 3 0 0 1 6 0v3" />
          </svg>
        </div>
      )}
    </div>
  );
}
